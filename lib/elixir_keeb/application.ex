defmodule ElixirKeeb.Application do
  @moduledoc false

  require Logger

  use Application

  def start(_type, _args) do
    Logger.info("⌨️  Starting ElixirKeeb 2022/06/27 22:32:05 ⌨️,")

    configure_wifi(target())

    device = configure_device(target())

    opts = [strategy: :one_for_one, name: ElixirKeeb.Supervisor]

    [
      matrix_scan_sample_size,
      matrix_to_usb_sample_size
    ] = [:matrix_scan, :matrix_to_usb]
        |> Enum.map(&Application.get_env(:elixir_keeb, :latency_tracker)[&1][:number_of_samples_kept])

    children =
      [
        ElixirKeeb.LatencyTracker.child_spec(
          :matrix_scan, matrix_scan_sample_size),
        ElixirKeeb.LatencyTracker.child_spec(
          :matrix_to_usb, matrix_to_usb_sample_size)
      ] ++ children(target(), device)

    Supervisor.start_link(children, opts)
  end

  def configure_device(:host), do: :no_device
  def configure_device(_target) do
    ElixirKeeb.Usb.Gadget.configure_device()
  end

  def children(:host, _device) do
    [
      # Children that only run on the host
    ]
  end

  def children(_target, device) do
    [
      # Children for all targets except host
      {ElixirKeeb.Gpio.Listener, []},
      {ElixirKeeb.Usb.Reporter, device}
    ]
  end

  def target() do
    Application.get_env(:elixir_keeb, :target)
  end

  def configure_wifi(:host), do: :no_device
  def configure_wifi(_target) do
    [{"wlan0", config} | _] = Application.get_env(:vintage_net, :config)

    Logger.info("Configuring wi-fi with #{inspect(config)}")

    result = VintageNet.configure("wlan0", config)

    Logger.info("Just configured wi-fi. Result: #{inspect(result)}")

    result
  end
end
