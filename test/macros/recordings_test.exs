defmodule ElixirKeeb.Macros.RecordingsTest do
  alias ElixirKeeb.Usb.Report

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

  defp regular_state do
    %{
      device: self(),
      layout: Fake.Layout.Module,
      input_report: Report.empty_report(),
      previous_layer: 0,
      layer: 0,
      activity: :regular,
    }
  end

  defp recording_state(slot, existing_recordings \\ nil)

  defp recording_state(slot, nil) do
    %{
      regular_state() |
      activity: {:recording, slot}
    }
  end

  defp recording_state(slot, existing_recordings) do
    existing_recordings = Map.put(%{}, slot, existing_recordings)

    %{
      regular_state() |
      activity: {:recording, slot},
    }
    |> Map.put(:recordings, existing_recordings)
  end
end
