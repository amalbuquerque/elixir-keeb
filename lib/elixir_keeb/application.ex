defmodule ElixirKeeb.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    device = configure_device(target())

    opts = [strategy: :one_for_one, name: ElixirKeeb.Supervisor]

    children =
      [] ++ children(target(), device)

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
      {ElixirKeeb.Usb.Reporter, [device]}
    ]
  end

  def target() do
    Application.get_env(:elixir_keeb, :target)
  end
end
