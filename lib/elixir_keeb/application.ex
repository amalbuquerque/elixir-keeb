defmodule ElixirKeeb.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    initialize(target())
    opts = [strategy: :one_for_one, name: ElixirKeeb.Supervisor]

    children =
      [] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  def initialize(:host), do: :noop
  def initialize(_target) do
    IO.puts("Starting USB HID Gadget...")
    ElixirKeeb.Usb.Gadget.configure_device()
    IO.puts("USB HID Gadget configured.")
  end

  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: ElixirKeeb.Worker.start_link(arg)
      # {ElixirKeeb.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: ElixirKeeb.Worker.start_link(arg)
      # {ElixirKeeb.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:elixir_keeb, :target)
  end
end
