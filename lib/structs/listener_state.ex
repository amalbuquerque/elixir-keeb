defmodule ElixirKeeb.Structs.ListenerState do
  alias ElixirKeeb.Gpio

  @fields [
    :line_ports,
    :column_ports,
    :reporter,
    :listener_wait_ms,
    :current_matrix
  ]

  @enforce_keys @fields
  defstruct @fields

  def initial_state(
    line_ports,
    column_ports,
    reporter_module,
    listener_wait_ms)
  when is_list(line_ports) and
  is_list(column_ports) and
  is_atom(reporter_module) and
  is_integer(listener_wait_ms) do
      %__MODULE__{
        line_ports: line_ports,
        column_ports: column_ports,
        reporter: reporter_module,
        listener_wait_ms: listener_wait_ms,
        current_matrix: Gpio.initial_matrix(line_ports, column_ports)
      }
  end
end
