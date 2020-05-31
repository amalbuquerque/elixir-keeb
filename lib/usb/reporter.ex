defmodule ElixirKeeb.Usb.Reporter do
  use GenServer
  require Logger
  alias ElixirKeeb.{Utils, KeycodeBehavior, Macros}
  alias ElixirKeeb.Macros.Recordings
  alias ElixirKeeb.Usb.{Report, Gadget}
  alias ElixirKeeb.Communication.WebDashboard

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

    {:ok, device_pid} = File.open(device, [:write])

    {
      :ok,
      %{
        device: device_pid,
        layout: layout_module,
        input_report: Report.empty_report(),
        previous_layer: 0,
        layer: 0,
        activity: :regular,
      }
    }
  end

  @impl true
  def handle_cast(
        {:keys_pressed, kc_xy_keys},
        %{
          device: device,
          input_report: previous_report,
          layout: _layout_module,
          previous_layer: _previous_layer,
          layer: _layer
        } = state
      ) do
    Logger.debug(
      "Received keys: #{inspect(kc_xy_keys)}, previous_report: #{inspect(previous_report)}"
    )

    new_state = update_input_report(kc_xy_keys, state)

    %{input_report: new_input_report} = new_state

    case new_input_report do
      ^previous_report ->
        Logger.debug("New input_report == previous input_report. Skipping writing to the device.")

        :noop

      _new_report ->
        Logger.debug(
          "New input_report != previous input_report. Writing #{inspect(new_input_report)} to device."
        )

        Gadget.raw_write(device, new_input_report)
    end

    {:noreply, new_state}
  end

  def update_input_report(
        kc_xy_keys,
        %{layout: layout_module} = state
      ) do
    Enum.reduce(kc_xy_keys, state, fn {kc_xy, action}, %{layer: current_layer} = state ->
      mapped_keycode = layout_module.keycode(kc_xy, current_layer)

      Logger.debug("Will now communicate to dashboard #{inspect({mapped_keycode, action})}...")
      WebDashboard.communicate({mapped_keycode, action})
      Logger.debug("Just communicated to dashboard #{inspect({mapped_keycode, action})}")

      handle_keycode_and_action(state, {mapped_keycode, action})
    end)
  end

  defp handle_keycode_and_action(
         %{layer: current_layer} = state,
         {
           %KeycodeBehavior{action: :toggle, layer: layer_to_toggle},
           :pressed
         }
       ) do
    %{state | previous_layer: current_layer, layer: layer_to_toggle}
  end

  defp handle_keycode_and_action(
         %{previous_layer: previous_layer} = state,
         {
           %KeycodeBehavior{action: :toggle, layer: layer_to_toggle},
           :released
         }
       ) do
    %{state | previous_layer: layer_to_toggle, layer: previous_layer}
  end

  defp handle_keycode_and_action(
         %{} = state,
         {
           %KeycodeBehavior{action: :macro, layer: _layer_to_toggle},
           :pressed
         }
       ) do
    # we only do something when a macro key is released
    state
  end

  defp handle_keycode_and_action(
         %{device: device} = state,
         {
           %KeycodeBehavior{action: :macro, function: macro_function},
           :released
         }
       ) do
    {macro_keys, new_state} = macro_function.(state)

    Logger.debug("Macro key was just released. Keys: #{inspect(macro_keys)}, this was the new state from the macro #{inspect(new_state)} (not being used yet)")

    Macros.send_macro_keys(device, macro_keys)

    # the macro function might have updated the state
    new_state
  end

  defp handle_keycode_and_action(
         %{} = state,
         {
           %KeycodeBehavior{action: :record, identifier: _slot},
           :pressed
         }
       ) do
    # we only do something when the record key is released
    state
  end

  defp handle_keycode_and_action(
         %{device: device, activity: {:recording, slot}} = state,
         {
           %KeycodeBehavior{action: :record, identifier: _},
           :released
         }
       ) do

    Logger.debug("Just recorded keypresses in slot #{slot}...")

    %{state | activity: :regular}
  end

  defp handle_keycode_and_action(
         %{device: device, activity: :regular} = state,
         {
           %KeycodeBehavior{action: :record, identifier: slot},
           :released
         }
       ) do

    Logger.debug("Will now record keypresses on slot #{slot}...")

    %{state | activity: {:recording, slot}}
  end

  defp handle_keycode_and_action(
         %{} = state,
         {
           %KeycodeBehavior{action: :lock, layer: _layer_to_toggle},
           :pressed
         }
       ) do
    # we only do something when a layer lock key is released
    state
  end

  defp handle_keycode_and_action(
         %{previous_layer: previous_layer, layer: current_layer} = state,
         {
           %KeycodeBehavior{action: :lock, layer: layer_to_lock},
           :released
         }
       ) do
    case current_layer do
      ^layer_to_lock ->
        # layer_to_lock was already activated, so we unlock it
        %{state | previous_layer: current_layer, layer: previous_layer}

      _ ->
        # layer_to_lock wasn't activated, so we lock it
        %{state | previous_layer: current_layer, layer: layer_to_lock}
    end
  end

  defp handle_keycode_and_action(
         %{input_report: previous_report} = state,
         {_mapped_keycode, _keycode_action} = keycode_and_action
       ) do
    input_report = Report.update_report(previous_report, keycode_and_action)

    state
    |> Recordings.maybe_record(keycode_and_action)
    |> Map.put(:input_report, input_report)
  end
end
