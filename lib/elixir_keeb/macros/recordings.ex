defmodule ElixirKeeb.Macros.Recordings do
  alias ElixirKeeb.Structs.ReporterState
  @type state :: map()
  @type keycode :: atom()
  @type action :: atom()
  @type slot :: integer()
  @type keycode_and_action :: {keycode, action}

  @callback maybe_record(state, keycode_and_action) :: state
  @callback get_recordings(state, slot) :: list(keycode_and_action)

  def maybe_record(%ReporterState{activity: :regular} = state, _keycode_and_action),
    do: state

  def maybe_record(%ReporterState{activity: {:recording, slot}} = state, keycode_and_action) do
    recordings = Map.get(state, :recordings, %{})

    recordings = update_slot(recordings, slot, keycode_and_action)

    Map.put(state, :recordings, recordings)
  end

  def get_recordings(state, slot) do
    state
    |> Map.get(:recordings, %{})
    |> Map.get(slot, [])
  end

  def erase_slot(%ReporterState{} = state, slot) do
    recordings = state
                 |> Map.get(:recordings, %{})
                 |> Map.put(slot, [])

    Map.put(state, :recordings, recordings)
  end

  defp update_slot(recordings, slot, keycode_and_action) do
    Map.update(recordings, slot, [keycode_and_action], fn previous_recording ->
      previous_recording ++ [keycode_and_action]
    end)
  end
end
