defmodule ElixirKeeb.UtilsTest do
  use ExUnit.Case

  @subject ElixirKeeb.Utils
  @config_key :bla
  @config_value "a configuration value"

  describe "get_config_or_raise/1" do
    test "when the config entry exists it returns a {key, value} tuple" do
      Application.put_env(:elixir_keeb, @config_key, @config_value)

      assert {@config_key, @config_value} == @subject.get_config_or_raise(@config_key)
    end

    test "when the config entry doesn't exist, it raises an error" do
      Application.delete_env(:elixir_keeb, @config_key)

      assert_raise RuntimeError, ~r/Please set the/, fn ->
        @subject.get_config_or_raise(@config_key)
      end
    end
  end

  describe "zip_with_index/2" do
    test "it zips each element starting from zero" do
      @subject.zip_with_index([:a, :b, :c])
      |> Enum.each(fn
        {:a, 0} -> :ok
        {:b, 1} -> :ok
        {:c, 2} -> :ok
      end)
    end

    test "it zips each element starting from a given integer" do
      @subject.zip_with_index([:a, :b, :c], -2)
      |> Enum.each(fn
        {:a, -2} -> :ok
        {:b, -1} -> :ok
        {:c, 0} -> :ok
      end)
    end
  end

  describe "zip_matrices/2" do
    test "it handles empty matrices" do
      assert [] == @subject.zip_matrices([], [])
    end

    test "it borks when matrices have different sizes" do
      assert_raise FunctionClauseError, fn ->
        @subject.zip_matrices([[]], [[:a]])
      end
    end

    test "it zips matrices" do
      result = @subject.zip_matrices(
        [[:a, :b, :c], [:d, :e, :f]],
        [[1, 2, 3], [4, 5, 6]]
      )

      assert result == [
        [{:a, 1}, {:b, 2}, {:c, 3}],
        [{:d, 4}, {:e, 5}, {:f, 6}],
      ]
    end
  end

  describe "kc/2" do
    test "it returns the expected atom (indexes between 0 and 9)" do
      for line_index <- 0..9 do
        for column_index <- 0..9 do
          assert String.to_atom("kc_#{line_index}#{column_index}") == @subject.kc(line_index, column_index)
        end
      end
    end

    test "it returns the expected atom (indexes between 'a' and 'z')" do
      for line_index <- 10..35 do
        for column_index <- 10..35 do
          expected = String.to_atom(
            "kc_#{<<?a + line_index - 10>>}#{<<?a + column_index - 10>>}")

          assert expected == @subject.kc(line_index, column_index)
        end
      end
    end
  end
end
