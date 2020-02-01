defmodule ElixirKeeb.Usb.Reporter do
  use GenServer
  require Logger
  alias ElixirKeeb.Utils
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
        layer: 0
      }
    }
  end

  @impl true
  def handle_cast(
        {:keys_pressed, kc_xy_keys},
    %{
      device: device,
      layout: layout_module,
      input_report: previous_report,
      layer: layer
    } = state
      ) do
    Logger.debug(
      "Received keys: #{inspect(kc_xy_keys)}, previous_report: #{inspect(previous_report)}"
    )

    keycodes_to_send =
      Enum.map(
        kc_xy_keys,
        fn {kc_xy, state} -> {layout_module.keycode(kc_xy, layer), state} end
      )

    new_input_report = Report.update_report_with_keys(previous_report, keycodes_to_send)

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

    {:noreply, %{state | input_report: new_input_report}}
  end
end
