defmodule ElixirKeeb.Usb.Reporter do
  use GenServer
  require Logger
  alias ElixirKeeb.{Utils, KeycodeBehavior}
  alias ElixirKeeb.Usb.{Report, Gadget}

  @empty_input_report <<0, 0, 0, 0, 0, 0, 0, 0>>

  def start_link(device) do
    config = [
      {:device, device},
      Utils.get_config_or_raise(:layout)
    ]

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init([device: device, layout: layout_module] = config) do
    Logger.debug("⌨️ Starting Usb.Reporter ⌨️,\n#{inspect(config)}")

    {
      :ok,
      %{
        device: device,
        layout: layout_module,
        input_report: @empty_input_report,
        previous_layer: 0,
        layer: 0
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
    Enum.reduce(kc_xy_keys, state, fn {kc_xy, state}, %{layer: current_layer} = acc ->
      mapped_keycode = layout_module.keycode(kc_xy, current_layer)

      handle_keycode_and_state(acc, {mapped_keycode, state})
    end)
  end

  defp handle_keycode_and_state(
         %{layer: current_layer} = state,
         {
           %KeycodeBehavior{action: :toggle, layer: layer_to_toggle},
           :pressed
         }
       ) do
    %{state | previous_layer: current_layer, layer: layer_to_toggle}
  end

  defp handle_keycode_and_state(
         %{previous_layer: previous_layer} = state,
         {
           %KeycodeBehavior{action: :toggle, layer: layer_to_toggle},
           :released
         }
       ) do
    %{state | previous_layer: layer_to_toggle, layer: previous_layer}
  end

  defp handle_keycode_and_state(
         %{input_report: previous_report} = state,
         {_mapped_keycode, _keycode_state} = keycode_and_state
       ) do
    input_report = Report.update_report(previous_report, keycode_and_state)

    %{state | input_report: input_report}
  end
end
