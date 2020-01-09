defmodule ElixirKeeb.Utils do
  @kc_indexes "0123456789abcdefghijklmnopqrstuvwxyz"

  def zip_with_index(list) do
    Enum.zip(list, 0..(length(list) - 1))
  end

  def zip_matrices(
        [line_a | rest_matrix_a] = matrix_a,
        [line_b | rest_matrix_b] = matrix_b
      )
      when length(matrix_a) == length(matrix_b) do
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
