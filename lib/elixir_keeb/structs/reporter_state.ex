defmodule ElixirKeeb.Structs.ReporterState do
  @empty_input_report ElixirKeeb.Usb.Report.empty_report()

  @fields [
    :device,
    :layout,
    :input_report,
    :previous_layer,
    :layer,
    :activity,
    :recordings,
    :tap_or_toggle_pending
  ]

  @enforce_keys @fields
  defstruct @fields

  def initial_state(device_pid, layout_module) when is_pid(device_pid) and is_atom(layout_module) do
      %__MODULE__{
        device: device_pid,
        layout: layout_module,
        input_report: @empty_input_report,
        previous_layer: 0,
        layer: 0,
        activity: :regular,
        recordings: %{},
        tap_or_toggle_pending: %{}
      }
  end
end
