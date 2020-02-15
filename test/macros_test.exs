defmodule ElixirKeeb.MacrosTest do
  use ExUnit.Case

  @subject ElixirKeeb.Macros

  describe "convert_to_keycode/1" do
    test "a 'basic' atom-based keycode is converted into a tap" do
      assert [
        {:kc_a, :pressed},
        {:kc_a, :released},
      ] == @subject.convert_to_keycode(:kc_a)
    end

    test "a 'basic' atom-based keycode with press/release info associated raises an exception" do
      for state <- [:pressed, :released] do
        assert_raise FunctionClauseError, fn ->
          @subject.convert_to_keycode({:kc_a, state})
        end
      end
    end

    test "a modifier keycode is converted into a press or release" do
      for state <- [:pressed, :released] do
        assert {:kc_lshift, state} == @subject.convert_to_keycode({:kc_lshift, state})
      end
    end

    test "a modifier keycode without press/release info associated raises an exception" do
      for modifier <- [:kc_lshift, :kc_rctrl, :kc_lgui, :kc_ralt] do
        assert_raise FunctionClauseError, fn ->
          @subject.convert_to_keycode(modifier)
        end
      end
    end
  end
end
