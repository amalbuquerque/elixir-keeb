defmodule ElixirKeeb.Utils do
  @kc_indexes "0123456789abcdefghijklmnopqrstuvwxyz"

  def monotonic_time do
    System.monotonic_time(:microsecond)
  end

  def matrix_at(matrix, x, y) do
    matrix
    |> Enum.at(x)
    |> Enum.at(y)
  end

  def get_config_or_raise(config_key) do
      value =
        Application.get_env(:elixir_keeb, config_key) ||
          raise("Please set the `:elixir_keeb, :#{config_key}` configuration entry")

      {config_key, value}
  end

  def zip_with_index(list, start_pos \\ 0) do
    Enum.zip(
      list, start_pos..(start_pos + length(list) - 1))
  end

  def zip_matrices(
    [line_a | rest_matrix_a] = matrix_a,
    [line_b | rest_matrix_b] = matrix_b
  )
  when length(matrix_a) == length(matrix_b)
  and length(line_a) == length(line_b) do
    [
      Enum.zip(line_a, line_b)
      | zip_matrices(rest_matrix_a, rest_matrix_b)
    ]
  end

  def zip_matrices([], []), do: []

  def kc(line_index, column_index) do
    line_kc_index = index_to_kc_index(line_index)
    column_kc_index = index_to_kc_index(column_index)

    String.to_atom("kc_#{line_kc_index}#{column_kc_index}")
  end

  defp index_to_kc_index(index)
       when is_integer(index) and index >= 0 and index <= 35 do
    String.at(@kc_indexes, index)
  end
end
