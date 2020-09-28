defmodule ElixirKeeb.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
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
end
