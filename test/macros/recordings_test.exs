defmodule ElixirKeeb.Macros.RecordingsTest do
  alias ElixirKeeb.Structs.ReporterState

  use ExUnit.Case

  @subject ElixirKeeb.Macros.Recordings

  @keycode_and_action {:kc_a, :pressed}
  @keycode_b_and_action {:kc_b, :pressed}

  describe "maybe_record/2" do
    test "it doesn't change the state during 'regular' activity" do
      state = regular_state()

      assert state == @subject.maybe_record(
        state, @keycode_and_action)
    end

    test "it records the keycode and action tuple when the state is 'recording'" do
      state = recording_state(1)

      new_state = @subject.maybe_record(
        state, @keycode_and_action)

      refute new_state == state

      slot_1_recordings = new_state
                          |> Map.get(:recordings)
                          |> Map.get(1)

      assert [@keycode_and_action] == slot_1_recordings
    end

    test "it records the keycode and action tuple when the state is 'recording' and there are existing recordings in the slot" do
      state = recording_state(1, [@keycode_and_action])

      new_state = @subject.maybe_record(
        state, @keycode_b_and_action)

      refute new_state == state

      slot_1_recordings = new_state
                          |> Map.get(:recordings)
                          |> Map.get(1)

      assert [@keycode_and_action, @keycode_b_and_action] == slot_1_recordings
    end
  end

  describe "erase_slot/2" do
    test "it doesn't bork with a regular state with no recordings" do
      state = regular_state()

      state = @subject.erase_slot(state, 0)

      assert @subject.get_recordings(state, 0) == []
    end

    test "it erases an existing slot from a state" do
      slot_1_recording = [@keycode_and_action, @keycode_and_action, @keycode_and_action]

      state = recording_state(1, slot_1_recording)
      state = recording_state(0, [@keycode_and_action], state)

      state = @subject.erase_slot(state, 0)

      assert @subject.get_recordings(state, 0) == []
      assert @subject.get_recordings(state, 1) == slot_1_recording
    end
  end

  defp regular_state,
    do: ReporterState.initial_state(self(), Fake.Layout.Module)

  defp recording_state(slot, existing_recordings \\ nil, initial_state \\ nil)

  defp recording_state(slot, nil, nil) do
    %ReporterState{
      regular_state() |
      activity: {:recording, slot}
    }
  end

  defp recording_state(slot, existing_recordings, initial_state) do
    initial_state = case initial_state do
      nil ->
        regular_state()

      state ->
        state
    end

    existing_recordings = Map.put(initial_state.recordings, slot, existing_recordings)

    %ReporterState{
      initial_state |
      activity: {:recording, slot},
    }
    |> Map.put(:recordings, existing_recordings)
  end
end
