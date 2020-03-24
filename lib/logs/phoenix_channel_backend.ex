defmodule ElixirKeeb.Logs.PhoenixChannelBackend do
  @moduledoc """
  Send log messages to front end
  """
  def init({__MODULE__, name}) do

    {:ok, configure(name, [])}
  end

  def handle_call({:configure, options}, %{name: name} = state) do
    {:ok, :ok, configure(name, options, state)}
  end

  def handle_event({_level, gl, {Logger, _, _, _}}, state) when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({level, _gl, {Logger, msg, _ts, meta}}, state) when is_binary(msg) do
    IO.puts("state: #{inspect(state)}")

    IO.puts("Log message level: #{level}")
    IO.puts("Log message: #{inspect(msg)}")
    IO.puts("Log metadata: #{inspect(meta)}")

    {:ok, state}
  end

  def handle_event({_level, _gl, {Logger, _, _, _}}, state) do
    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp configure(name, opts) do
    state = %{name: nil, module: nil, function: nil}

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    module = Keyword.get(opts, :module)
    function = Keyword.get(opts, :function)

    %{state | name: name, module: module, function: function}
  end
end
