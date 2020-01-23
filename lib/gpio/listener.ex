defmodule ElixirKeeb.Gpio.Listener do
  use GenServer
  require Logger
  alias ElixirKeeb.{Utils, Gpio}
  alias Circuits.GPIO, as: CircuitsGPIO

  @default_listener_wait_ms 10

  def start_link(_) do
    config = get_config()

    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(
        [
          line_pins: line_pins,
          column_pins: column_pins,
          reporter: reporter,
          listener_wait_ms: listener_wait_ms
        ] = args
      ) do
    Logger.debug("⌨️ Starting Gpio.Listener ⌨️,\n#{inspect(args)}")

    line_ports = Gpio.open_ports(line_pins, :output)
    column_ports = Gpio.open_ports(column_pins, :input)

    GenServer.cast(self(), :scan_matrix)

    {
      :ok,
      %{
        line_ports: line_ports,
        column_ports: column_ports,
        reporter: reporter,
        listener_wait_ms: listener_wait_ms,
        current_matrix: Gpio.initial_matrix(line_pins, column_pins)
      }
    }
  end

  @impl true
  def handle_cast(:scan_matrix,
    %{
      line_ports: line_ports,
      column_ports: column_ports,
      reporter: reporter,
      listener_wait_ms: listener_wait_ms,
      current_matrix: current_matrix
    } = state) do

    new_matrix = Gpio.scan_matrix(line_ports, column_ports, listener_wait_ms)

    case Gpio.diff_matrices(current_matrix, new_matrix) do
      [] ->
        :noop

      keys_pressed ->
        GenServer.cast(reporter, {:keys_pressed, keys_pressed})
    end

    GenServer.cast(self(), :scan_matrix)

    {:noreply, state}
  end

  defp get_config() do
    wait_ms = Application.get_env(:elixir_keeb, :listener_wait_ms) || @default_listener_wait_ms

    [:line_pins, :column_pins, :reporter]
    |> Enum.map(&Utils.get_config_or_raise/1)
    |> Kernel.++(listener_wait_ms: wait_ms)
  end
end
