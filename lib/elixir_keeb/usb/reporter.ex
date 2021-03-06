defmodule ElixirKeeb.Usb.Reporter do
  use GenServer
  require Logger
  alias ElixirKeeb.{Utils, LatencyTracker}
  alias ElixirKeeb.Structs.{
    KeycodeBehavior,
    ReporterState,
    KeyChange
  }

  @gadget Application.get_env(:elixir_keeb, :modules)[:gadget]
  @report Application.get_env(:elixir_keeb, :modules)[:report]
  @macros Application.get_env(:elixir_keeb, :modules)[:macros]
  @tap_or_toggle Application.get_env(:elixir_keeb, :modules)[:tap_or_toggle]
  @recordings Application.get_env(:elixir_keeb, :modules)[:recordings]
  @web_dashboard Application.get_env(:elixir_keeb, :modules)[:web_dashboard]

  def start_link(device) do
    config = [
      {:device, device},
      Utils.get_config_or_raise(:layout)
    ]

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init([device: device, layout: layout_module] = config) do
    Logger.info("⌨️ Starting Usb.Reporter ⌨️,\n#{inspect(config)}")

    {:ok, device_pid} = @gadget.open_device(device)

    {
      :ok,
      ReporterState.initial_state(device_pid, layout_module)
    }
  end

  @impl true
  def handle_call(:state, _from, state) do
    Logger.debug(
      "Returning current state: #{inspect(state)}")

    {:reply, state, state}
  end

  @impl true
  def handle_call({:new_state, new_state}, _from, state) do
    Logger.debug(
      "Previous state is: #{inspect(state)}\nSetting current state as: #{inspect(new_state)}")

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast(
        {:keys_pressed, [%KeyChange{} | _rest] = kc_xy_keys},
        %ReporterState{
          device: device,
          input_report: previous_report
        } = state
      ) do
    Logger.debug(
      "Received keys: #{inspect(kc_xy_keys)}, previous_report: #{inspect(previous_report)}"
    )

    new_state = update_input_report(kc_xy_keys, state)

    %ReporterState{input_report: new_input_report} = new_state

    case new_input_report do
      ^previous_report ->
        Logger.debug("New input_report == previous input_report. Skipping writing to the device.")

        :noop

      _new_report ->
        Logger.debug(
          "New input_report != previous input_report. Writing #{inspect(new_input_report)} to device."
        )

        @gadget.raw_write(device, new_input_report)
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        {:keycode_behaviors_pressed, [{%KeycodeBehavior{}, _action} | _rest] = keycode_behavior_keys},
        %ReporterState{
          device: device,
          input_report: previous_report
        } = state
      ) do
    Logger.debug(
      "Received keycode behaviors: #{inspect(keycode_behavior_keys)}, previous_report: #{inspect(previous_report)}"
    )

    # TODO: Refactor this part, given its similarity with the
    # handle_cast({:keys_pressed, ...}, ...) above
    new_state = update_input_report(keycode_behavior_keys, state)

    %ReporterState{input_report: new_input_report} = new_state

    case new_input_report do
      ^previous_report ->
        Logger.debug("New input_report == previous input_report. Skipping writing to the device.")

        :noop

      _new_report ->
        Logger.debug(
          "New input_report != previous input_report. Writing #{inspect(new_input_report)} to device."
        )

        @gadget.raw_write(device, new_input_report)
    end

    {:noreply, new_state}
  end

  def update_input_report(
        [%KeyChange{} | _rest] = kc_xy_keys,
        %ReporterState{layout: layout_module} = state
      ) do
    Enum.reduce(
      kc_xy_keys,
      state,
      fn %KeyChange{
        kc_xy: kc_xy,
        state: action
      } = key_change, %ReporterState{layer: current_layer} = state ->
      mapped_keycode = layout_module.keycode(kc_xy, current_layer)

      measure_latency(key_change)

      Logger.debug("Will now communicate to dashboard #{inspect({mapped_keycode, action})}...")
      @web_dashboard.communicate({mapped_keycode, action})
      Logger.debug("Just communicated to dashboard #{inspect({mapped_keycode, action})}")

      handle_keycode_and_action(state, {mapped_keycode, action})
    end)
  end

  def update_input_report(
        [{%KeycodeBehavior{}, _action} | _rest] = keycode_behavior_keys,
        %ReporterState{} = state
      ) do
    Enum.reduce(
      keycode_behavior_keys,
      state,
      fn {%KeycodeBehavior{} = mapped_keycode, action},
         %ReporterState{} = state ->

      Logger.debug("Will now communicate to dashboard #{inspect({mapped_keycode, action})}...")
      @web_dashboard.communicate({mapped_keycode, action})
      Logger.debug("Just communicated to dashboard #{inspect({mapped_keycode, action})}")

      handle_keycode_and_action(state, {mapped_keycode, action})
    end)
  end

  defp handle_keycode_and_action(
         %ReporterState{layer: current_layer} = state,
         {
           %KeycodeBehavior{action: :toggle, layer: layer_to_toggle},
           :pressed
         }
       ) do
    %ReporterState{state | previous_layer: current_layer, layer: layer_to_toggle}
  end

  defp handle_keycode_and_action(
         %ReporterState{previous_layer: previous_layer} = state,
         {
           %KeycodeBehavior{action: :toggle, layer: layer_to_toggle},
           :released
         }
       ) do
    %ReporterState{state | previous_layer: layer_to_toggle, layer: previous_layer}
  end

  defp handle_keycode_and_action(
         %ReporterState{} = state,
         {
           %KeycodeBehavior{action: :macro},
           :pressed
         }
       ) do
    # we only do something when a macro key is released
    state
  end

  defp handle_keycode_and_action(
         %ReporterState{device: device} = state,
         {
           %KeycodeBehavior{action: :macro, function: macro_function},
           :released
         }
       ) do
    {macro_keys, new_state} = macro_function.(state)

    Logger.debug("Macro key was just released. Keys: #{inspect(macro_keys)}, this was the new state from the macro #{inspect(new_state)}")

    @macros.send_macro_keys(device, macro_keys)

    # the macro function might have updated the state
    new_state
  end

  defp handle_keycode_and_action(
         %ReporterState{} = state,
         {
           %KeycodeBehavior{action: :record, identifier: _slot},
           :pressed
         }
       ) do
    # we only do something when the record key is released
    state
  end

  defp handle_keycode_and_action(
         %ReporterState{activity: {:recording, slot}} = state,
         {
           %KeycodeBehavior{action: :record, identifier: _},
           :released
         }
       ) do

    Logger.debug("Just recorded keypresses in slot #{slot}...")

    %ReporterState{state | activity: :regular}
  end

  defp handle_keycode_and_action(
         %ReporterState{activity: :regular} = state,
         {
           %KeycodeBehavior{action: :record, identifier: slot},
           :released
         }
       ) do

    state = @recordings.erase_slot(state, slot)

    Logger.debug("Will now record keypresses on slot #{slot}... (after emptying the sloto first)")

    %ReporterState{state | activity: {:recording, slot}}
  end

  defp handle_keycode_and_action(
         %ReporterState{} = state,
         {
           %KeycodeBehavior{action: :replay, identifier: _slot},
           :pressed
         }
       ) do
    # we only do something when the replay key is released
    state
  end

  defp handle_keycode_and_action(
         %ReporterState{device: device} = state,
         {
           %KeycodeBehavior{action: :replay, identifier: slot},
           :released
         }
       ) do

    to_replay = @recordings.get_recordings(state, slot)

    Logger.debug("Will now replay slot #{slot} recordings: #{inspect(to_replay)}")

    @macros.send_macro_keys(device, to_replay)

    # replaying recordings doesn't change the state
    state
  end

  defp handle_keycode_and_action(
         %ReporterState{} = state,
         {
           %KeycodeBehavior{action: :lock, layer: _layer_to_toggle},
           :pressed
         }
       ) do
    # we only do something when a layer lock key is released
    state
  end

  defp handle_keycode_and_action(
         %ReporterState{previous_layer: previous_layer, layer: current_layer} = state,
         {
           %KeycodeBehavior{action: :lock, layer: layer_to_lock},
           :released
         }
       ) do
    case current_layer do
      ^layer_to_lock ->
        # layer_to_lock was already activated, so we unlock it
        %ReporterState{state | previous_layer: current_layer, layer: previous_layer}

      _ ->
        # layer_to_lock wasn't activated, so we lock it
        %ReporterState{state | previous_layer: current_layer, layer: layer_to_lock}
    end
  end

  defp handle_keycode_and_action(
    %ReporterState{} = state,
    {
      %KeycodeBehavior{action: :tap_or_toggle},
      _key_state
    } = keycode_and_action
  ) do
    @tap_or_toggle.handle_tap_or_toggle(state, keycode_and_action)
  end

  defp handle_keycode_and_action(
         %ReporterState{input_report: previous_report} = state,
         {_mapped_keycode, _keycode_action} = keycode_and_action
       ) do
    input_report = @report.update_report(previous_report, keycode_and_action)

    state
    |> @recordings.maybe_record(keycode_and_action)
    |> Map.put(:input_report, input_report)
  end

  defp measure_latency(%KeyChange{read_at: read_at}) do
    now = Utils.monotonic_time()

    :ok = LatencyTracker.append(:matrix_to_usb, now - read_at)
  end
end
