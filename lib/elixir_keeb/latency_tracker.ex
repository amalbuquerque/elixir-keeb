defmodule ElixirKeeb.LatencyTracker do
  use GenServer

  def child_spec(name, max_size) do
    %{
      id: name,
      start: {
        __MODULE__,
        :new,
        [[max_size, [name: name]]]
      }
    }
  end

  @impl true
  def init(max_size) do
    {:ok, %{data: [], max: max_size}}
  end

  @impl true
  def handle_call({:get, :all}, _from, %{data: data} = state) do
    to_return = Enum.reverse(data)

    {:reply, to_return, state}
  end

  @impl true
  def handle_call({:get, how_many}, _from, %{data: data} = state) when how_many > 0 do
    to_return = data
           |> Enum.take(how_many)
           |> Enum.reverse()

    {:reply, to_return, state}
  end

  @impl true
  def handle_cast({:add, new_item}, %{data: data, max: max} = state) do
    state = %{state | data: append_data(data, new_item, max)}

    {:noreply, state}
  end

  def new([init_arg, options]) do
    new(init_arg, options)
  end

  def new(init_arg, options \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, init_arg, options)
  end

  def get, do: get(__MODULE__)

  def get(how_many) when is_integer(how_many),
    do: get(__MODULE__, how_many)

  def get(server) when is_atom(server) or is_pid(server) do
    GenServer.call(server, {:get, :all})
  end

  def get(server, how_many)
    when (is_atom(server) or is_pid(server)) and is_integer(how_many) do
    GenServer.call(server, {:get, how_many})
  end

  def append(server, new_item) do
    GenServer.cast(server, {:add, new_item})
  end

  defp append_data(data, new_item, max) when length(data) < max,
    do: [new_item | data]

  defp append_data(data, new_item, max),
    do: [new_item | data]
        |> Enum.take(max)
end
