defmodule ElixirKeeb.Gpio.Listener do
  use GenServer
  require Logger
  alias ElixirKeeb.{Utils, Gpio, LatencyTracker}
  alias ElixirKeeb.Structs.ListenerState

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
    Logger.info("⌨️ Starting Gpio.Listener ⌨️,\n#{inspect(args)}")

    line_ports = Gpio.open_ports(line_pins, :output)
    column_ports = Gpio.open_ports(column_pins, :input)

    GenServer.cast(self(), :scan_matrix)

    {
      :ok,
      ListenerState.initial_state(
        line_ports,
        column_ports,
        reporter,
        listener_wait_ms
      )
    }
  end

  @impl true
  def handle_cast(
        :scan_matrix,
        %ListenerState{
          line_ports: line_ports,
          column_ports: column_ports,
          reporter: reporter,
          listener_wait_ms: listener_wait_ms,
          current_matrix: current_matrix
        } = state
      ) do
    new_matrix = Gpio.scan_matrix(line_ports, column_ports, listener_wait_ms)

    new_state =
      case Gpio.diff_matrices(current_matrix, new_matrix) do
        [] ->
          state

        keys_pressed ->
          Logger.debug(inspect(keys_pressed), label: "Listener detected keys pressed")

          GenServer.cast(reporter, {:keys_pressed, keys_pressed})

          %ListenerState{state | current_matrix: new_matrix}
      end

    new_state = measure_latency(new_state)

    GenServer.cast(self(), :scan_matrix)

    {:noreply, new_state}
  end

  defp measure_latency(%ListenerState{last_scan_at: last_scan_at} = state) do
    now = Utils.monotonic_time()

    :ok = LatencyTracker.append(:matrix_scan, now - last_scan_at)

    %{state | last_scan_at: now}
  end

  defp get_config() do
    wait_ms = Application.get_env(:elixir_keeb, :listener_wait_ms) || @default_listener_wait_ms

    [:line_pins, :column_pins, :reporter]
    |> Enum.map(&Utils.get_config_or_raise/1)
    |> Kernel.++(listener_wait_ms: wait_ms)
  end
end
