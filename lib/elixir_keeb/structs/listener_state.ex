defmodule ElixirKeeb.Structs.ListenerState do
  alias ElixirKeeb.{Gpio, Utils}

  @fields [
    :line_ports,
    :column_ports,
    :reporter,
    :listener_wait_ms,
    :current_matrix,
    :last_scan_at
  ]

  @enforce_keys @fields
  defstruct @fields

  def initial_state(
    line_ports,
    column_ports,
    reporter_module,
    listener_wait_ms)
  when is_map(line_ports) and
  is_map(column_ports) and
  is_atom(reporter_module) and
  is_integer(listener_wait_ms) do
    line_pins = Map.keys(line_ports)
    column_pins = Map.keys(column_ports)

      %__MODULE__{
        line_ports: line_ports,
        column_ports: column_ports,
        reporter: reporter_module,
        listener_wait_ms: listener_wait_ms,
        current_matrix: Gpio.initial_matrix(line_pins, column_pins),
        last_scan_at: Utils.monotonic_time()
      }
  end
end
