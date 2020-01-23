defmodule ElixirKeeb.Gpio do
  alias Circuits.GPIO, as: CircuitsGPIO
  alias ElixirKeeb.Utils

  require Logger

  def open_ports(pins, direction) when direction in [:input, :output] do
    pins
    |> Enum.map(fn {matrix_port, pin} ->
      {:ok, gpio} = CircuitsGPIO.open(pin, direction)

      CircuitsGPIO.set_pull_mode(gpio, :pulldown)

      {matrix_port, gpio}
    end)
    |> Enum.into(%{})
  end

  def initial_matrix(line_pins, column_pins) do
    for _line <- 0..(length(line_pins) - 1) do
      for _column <- 0..(length(column_pins) - 1) do
        0
      end
    end
  end

  def scan_matrix(line_ports, column_ports, wait_ms) do
    for {_line_port, line_gpio} <- line_ports do
      CircuitsGPIO.write(line_gpio, 1)

      line_reads =
        for {_column_port, column_gpio} <- column_ports do
          read = CircuitsGPIO.read(column_gpio)

          Process.sleep(wait_ms)

          read
        end

      CircuitsGPIO.write(line_gpio, 0)

      line_reads
    end
  end

  def diff_matrices(current_matrix, new_matrix, line_index \\ 0)

  def diff_matrices(
        [current_line | rest_current_lines] = current_matrix,
        [new_line | rest_new_lines] = new_matrix,
        line_index
      )
      when length(current_matrix) == length(new_matrix) and length(current_line) == length(new_line) do
    [
      diff_lines(current_line, new_line, line_index)
      | diff_matrices(rest_current_lines, rest_new_lines, line_index + 1)
    ] |> List.flatten()
  end

  def diff_matrices([], [], _), do: []

  def diff_lines(current_line, new_line, line_index, column_index \\ 0)

  def diff_lines(
        [current_position | rest_current_line] = current_line,
        [new_position | rest_new_line] = new_line,
        line_index,
        column_index
      )
      when length(current_line) == length(new_line) do
    diff_position(
      current_position,
      new_position,
      line_index,
      column_index
    )
    |> case do
      {_line_idx, _col_idx, :same} ->
        diff_lines(
          rest_current_line,
          rest_new_line,
          line_index,
          column_index + 1
        )

      {line_idx, col_idx, diff} ->
        [
          {Utils.kc(line_idx, col_idx), diff}
          | diff_lines(
              rest_current_line,
              rest_new_line,
              line_index,
              column_index + 1
            )
        ]
    end
  end

  def diff_lines([], [], _, _), do: []

  def diff_position(x, x, line_index, column_index) when x == x do
    {line_index, column_index, :same}
  end

  def diff_position(0, 1, line_index, column_index) do
    {line_index, column_index, :pressed}
  end

  def diff_position(1, 0, line_index, column_index) do
    {line_index, column_index, :released}
  end
end
