defmodule ElixirKeeb.Macros.Recordings do
  @type state :: map()
  @type keycode :: atom()
  @type action :: atom()
  @type keycode_and_action :: {keycode, action}
  @callback maybe_record(state, keycode_and_action) :: state

  def maybe_record(%{activity: :regular} = state, _keycode_and_action),
    do: state

  def maybe_record(%{activity: {:recording, slot}} = state, keycode_and_action) do
    recordings = Map.get(state, :recordings, %{})

    recordings = update_slot(recordings, slot, keycode_and_action)

    Map.put(state, :recordings, recordings)
  end

  defp update_slot(recordings, slot, keycode_and_action) do
    Map.update(recordings, slot, [keycode_and_action], fn previous_recording ->
      previous_recording ++ [keycode_and_action]
    end)
  end
end
