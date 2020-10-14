defmodule ElixirKeeb.Advanced.TapOrToggle do
  require Logger
  alias ElixirKeeb.Utils
  alias ElixirKeeb.Structs.{
    KeycodeBehavior,
    ReporterState
  }

  # TODO: Move to configuration
  @debounce_time_ms 100
  @macros Application.get_env(:elixir_keeb, :modules)[:macros]

  def handle_tap_or_toggle(
    %ReporterState{tap_or_toggle_pending: pending} = reporter_state,
    {
      %KeycodeBehavior{action: :tap_or_toggle} = keycode_behavior,
      _key_state
    } = keycode_behavior_and_state) do

      tap_or_toggle_type = keycode_behavior.tap_or_toggle.type
      is_pending = is_pending(pending, keycode_behavior)
      before_or_after_debounce = before_or_after_debounce(keycode_behavior, pending)

      Logger.debug("Will now TapOrToggle.handle:\n#{inspect(keycode_behavior_and_state)},\nType: #{tap_or_toggle_type},\nPending? #{is_pending},\nBefore or after debounce? #{before_or_after_debounce}")

      handle(
        keycode_behavior_and_state,
        tap_or_toggle_type,
        is_pending,
        before_or_after_debounce,
        reporter_state
      )
    end

  # Scenario A
  defp handle({key_behavior, :pressed}, :regular, :not_pending, _before_or_after_debounce, %ReporterState{tap_or_toggle_pending: pending} = reporter_state) do
    wait_until = Utils.monotonic_time + @debounce_time_ms

    pending = set_pending(pending, key_behavior, wait_until)

    debounced_key_behavior = debounced(key_behavior)

    Utils.cast_after(
      reporter(),
      {:keycode_behaviors_pressed, [{debounced_key_behavior, :pressed}]},
      @debounce_time_ms
    )

    %{reporter_state | tap_or_toggle_pending: pending}
  end

  # Scenario C
  defp handle({_key_behavior, :pressed}, :debounced, :not_pending, _before_or_after_debounce, %ReporterState{tap_or_toggle_pending: _pending} = reporter_state) do
    # the ToT is not pending, so it must have been released by now

    # NOP
    reporter_state
  end

  # Scenario F
  defp handle({key_behavior, :released}, :regular, :is_pending, :before_debounce,
    %ReporterState{tap_or_toggle_pending: pending} = reporter_state) do
    pending = pop_from_pending(pending, key_behavior)
    reporter_state = %{reporter_state | tap_or_toggle_pending: pending}

    tap_key(reporter_state, key_behavior)
  end

  # Scenario H
  defp handle({key_behavior, :released}, :regular, :is_pending, :after_debounce,
    %ReporterState{tap_or_toggle_pending: pending} = reporter_state) do
    pending = pop_from_pending(pending, key_behavior)
    reporter_state = %{reporter_state | tap_or_toggle_pending: pending}

    send_toggle(reporter_state, key_behavior, :released)
  end

  # Scenario G
  defp handle({key_behavior, :pressed}, :debounced, :is_pending,
    _before_or_after_debounce, %ReporterState{} = reporter_state) do
    # we don't pop from pending since it will be popped when the key is released

    send_toggle(reporter_state, key_behavior, :pressed)
  end

  defp handle({_key_behavior, _state}, _tot_type, _is_pending, _before_or_after_debounce,
    %ReporterState{tap_or_toggle_pending: _pending} = reporter_state) do
    Logger.debug("TapOrToggle.handle/6 being called and ignored")

    reporter_state
  end

  defp before_or_after_debounce(%KeycodeBehavior{action: :tap_or_toggle} = keycode_behavior, %{} = pending) do
    tap_or_toggle_key = pending_tap_or_toggle_key(keycode_behavior)

    with debounce_time when is_integer(debounce_time) <- Map.get(pending, tap_or_toggle_key) do
      if debounce_time > Utils.monotonic_time() do
        :before_debounce
      else
        :after_debounce
      end
    else
      nil ->
        :no_pending_tot_to_calculate_if_before_or_after
    end
  end

  defp debounced(%KeycodeBehavior{action: :tap_or_toggle} = keycode_behavior) do
    %{keycode_behavior |
      tap_or_toggle: Map.put(keycode_behavior.tap_or_toggle, :type, :debounced)}
  end

  defp pending_tap_or_toggle_key(%KeycodeBehavior{
    action: :tap_or_toggle,
    tap_or_toggle: %{
      tap: tap,
      toggle: toggle
    }}) do
      "tap_#{inspect(tap)}_or_toggle_#{inspect(toggle)}"
  end

  defp is_pending(pending, %KeycodeBehavior{action: :tap_or_toggle} = key_behavior) do
    tap_or_toggle_key = pending_tap_or_toggle_key(key_behavior)

    case tap_or_toggle_key in Map.keys(pending) do
      true ->
        :is_pending

      false ->
        :not_pending
    end
  end

  defp set_pending(pending, %KeycodeBehavior{action: :tap_or_toggle} = key_behavior, wait_until) do
    tap_or_toggle_key = pending_tap_or_toggle_key(key_behavior)
    Logger.debug("Setting #{inspect(tap_or_toggle_key)} as pending until #{wait_until}")

    Map.update(pending, tap_or_toggle_key, wait_until, fn previous_wait_until ->
      Logger.warn("Setting #{inspect(tap_or_toggle_key)} as pending until #{wait_until} when the similar key change was already pending until #{previous_wait_until}.")

      wait_until
    end)
  end

  defp pop_from_pending(pending, %KeycodeBehavior{action: :tap_or_toggle} = key_behavior) do
    tap_or_toggle_key = pending_tap_or_toggle_key(key_behavior)
    Logger.debug("Popping #{inspect(tap_or_toggle_key)} from pending.")

    Map.delete(pending, tap_or_toggle_key)
  end

  defp tap_key(
    %ReporterState{device: device, input_report: previous_input_report} = state,
    %KeycodeBehavior{tap_or_toggle: %{tap: tap_key}}) do
      Logger.debug("Tapping macro keys #{inspect(tap_key)}")

      input_report = @macros.send_macro_keys(
        device, [tap_key], previous_input_report)

      %{state | input_report: input_report}
  end

  defp send_toggle(
    %ReporterState{device: device, input_report: previous_input_report} = state,
    %KeycodeBehavior{tap_or_toggle: %{toggle: toggle_key}},
    key_state) do
      input_report = @macros.send_macro_keys(
        device, [{toggle_key, key_state}], previous_input_report)

      %{state | input_report: input_report}
  end

  defp reporter do
    {:reporter, reporter} = Utils.get_config_or_raise(:reporter)

    reporter
  end
end
