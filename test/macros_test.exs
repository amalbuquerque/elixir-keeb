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

    test "a 'basic' string-based keycode is converted into a tap" do
      assert [
        {:kc_a, :pressed},
        {:kc_a, :released},
      ] == @subject.convert_to_keycode("a")
    end

    test "a 'basic' atom-based keycode with press/release info associated raises an exception" do
      for state <- [:pressed, :released] do
        assert_raise FunctionClauseError, fn ->
          @subject.convert_to_keycode({:kc_a, state})
        end
      end
    end

    test "a 'basic' string-based keycode with press/release info associated raises an exception" do
      for state <- [:pressed, :released] do
        assert_raise RuntimeError, fn ->
          @subject.convert_to_keycode({"a", state})
        end
      end
    end

    test "a modifier keycode is converted into a press or release" do
      for state <- [:pressed, :released] do
        assert {:kc_lshift, state} == @subject.convert_to_keycode({:kc_lshift, state})
      end
    end

    test "a *binary* modifier keycode is converted into a press or release" do
      for state <- [:pressed, :released] do
        assert {:kc_lshift, state} == @subject.convert_to_keycode({"lshift", state})
      end
    end

    test "a modifier keycode without press/release info associated raises an exception" do
      for modifier <- [:kc_lshift, :kc_rctrl, :kc_lgui, :kc_ralt] do
        assert_raise FunctionClauseError, fn ->
          @subject.convert_to_keycode(modifier)
        end
      end
    end

    test "a *binary* modifier keycode without press/release info associated raises an exception" do
      for modifier <- ["lshift", "rctrl", "lgui", "ralt"] do
        assert_raise RuntimeError, fn ->
          @subject.convert_to_keycode(modifier)
        end
      end
    end

    test "a *binary* shifted key is converted as expected" do
      expectations = %{
        "!" => shifted_expanded(:kc_1),
        "#" => shifted_expanded(:kc_3),
        "A" => shifted_expanded(:kc_a),
        "<" => shifted_expanded(:kc_comma),
        "[" => [{:kc_lbracket, :pressed}, {:kc_lbracket, :released}],
        " " => [{:kc_space, :pressed}, {:kc_space, :released}]
      }

      for shifted_key <- Map.keys(expectations) do
        assert expectations[shifted_key] == @subject.convert_to_keycode(shifted_key)
      end
    end

    test "a *binary* shifted key is converted as a 'basic' atom-based keycode is" do
      expectations = %{
        "[" => :kc_lbracket,
        " " => :kc_space,
        "-" => :kc_minus
      }

      for shifted_key <- Map.keys(expectations) do
        assert @subject.convert_to_keycode(shifted_key) == @subject.convert_to_keycode(expectations[shifted_key])
      end
    end
  end

  defp shifted_expanded(keycode) do
    [{:kc_lshift, :pressed}, {keycode, :pressed}, {keycode, :released}, {:kc_lshift, :released}]
  end
end
