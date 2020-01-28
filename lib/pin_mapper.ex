defmodule ElixirKeeb.PinMapper do
  @moduledoc """
  Imagine a 3x4 keyboard like this:

  -----------------
  | Q | W | E | R |
  | A | S | D | F |
  | Z | X | C | V |
  -----------------

  The controller has 8 pins, P1, P2, ..., P7, P8.

  (A)
  P1, P3, P5, P8 => "Lines"
  P2, P4, P6, P7 => "Columns"

  Each key connected to "randomly" assigned pins:

  (B)
  ---------------------------------
  | P1,P4 | P3,P2 | P1,P7 | P3,P6 |
  | P3,P7 | P1,P6 | P8,P6 | P5,P7 |
  | P5,P2 | P5,P4 | P3,P4 | P8,P2 |
  ---------------------------------

  We want a way to say Q corresponds to P1,P4,
  W corresponds to P3,P2, and so on.

  In the end we want a matrix like this:

  (C)
  [                               #         kx0:P2  kx1:P4  kx2:P6  kx3:P7  cols
    [kc_no, k01,   k02,   k03  ], # k0y:P1  P1,P2   P1,P4   P1,P6   P1,P7
    [k10,   k11,   k12,   k13  ], # k1y:P3  P3,P2   P3,P4   P3,P6   P3,P7
    [k20,   k21,   kc_no, k23  ], # k2y:P5  P5,P2   P5,P4   P5,P6   P5,P7
    [k30,   kc_no, k32,   kc_no], # k3y:P8  P8,P2   P8,P4   P8,P6   P8,P7
  ]                               #    rows

  Where `kc_no` means this pin combination isn't
  connected to any key.

  The QMK macro receives:

  [
    [k01, k10, k03, k12],
    [k13, k02, k32, k23],
    [k20, k21, k11, k30],
  ]

  The QMK macro maps the "physical" matrix to the pin matrix.

  With the list of pins (A) and the "matrix" (B), we're able
  to create the (C) end result.
  """

  alias ElixirKeeb.Utils
  require Logger

  @disabled_keycode :kc_no

  @doc """
  Receives the "physical" matrix,
  the list of line pins and column pins,
  and returns the physical matrix using the `:kc_xy` representation.

  If the `line_pins` look like (ie., `{:alias, pin_number}`):

  ```
  [{:P1, 1}, {:P3, 3}, {:P5, 5}, {:P8, 8}]
  ```

  And the `column_pins` look like (ie., `{:alias, pin_number}`):

  ```
  [{:P2, 2}, {:P4, 4}, {:P6, 6}, {:P7, 7}]
  ```

  The keyboard is a 3x4 keeb, so the physical_matrix
  has 3 lists of 4 elements each:

  ```
  [
    [ {:P1, :P4} , {:P3, :P2} , {:P1, :P7} , {:P3, :P6} ],
    [ {:P3, :P7} , {:P1, :P6} , {:P8, :P6} , {:P5, :P7} ],
    [ {:P5, :P2} , {:P5, :P4} , {:P3, :P4} , {:P8, :P2} ],
  ]
  ```

  It returns the following physical matrix in `:kc_xy` representation:

  ```
  [
    [:kc_01, :kc_10, :kc_03, :kc_12],
    [:kc_13, :kc_02, :kc_32, :kc_23],
    [:kc_20, :kc_21, :kc_11, :kc_30],
  ]
  """
  def physical_matrix_kc_xy(physical_matrix, lines: line_pins, columns: column_pins) do
    for matrix_line <- physical_matrix do
      for {line_pin, column_pin} <- matrix_line do
        line_index = index_in_pin_list(line_pin, line_pins)
        column_index = index_in_pin_list(column_pin, column_pins)

        Utils.kc(line_index, column_index)
      end
    end
  end

  @doc """
  Receives the "physical" matrix,
  the list of line pins and column pins,
  and returns the pin matrix.

  If the `line_pins` look like (ie., `{:alias, pin_number}`):

  ```
  [{:P1, 1}, {:P3, 3}, {:P5, 5}, {:P8, 8}]
  ```

  And the `column_pins` look like (ie., `{:alias, pin_number}`):

  ```
  [{:P2, 2}, {:P4, 4}, {:P6, 6}, {:P7, 7}]
  ```

  The keyboard is a 3x4 keeb, so the physical_matrix
  has 3 lists of 4 elements each:

  ```
  [
    [ {:P1, :P4} , {:P3, :P2} , {:P1, :P7} , {:P3, :P6} ],
    [ {:P3, :P7} , {:P1, :P6} , {:P8, :P6} , {:P5, :P7} ],
    [ {:P5, :P2} , {:P5, :P4} , {:P3, :P4} , {:P8, :P2} ],
  ]
  ```

  It returns the following pin matrix (we have 4 line pins
  and 4 column pins, hence we have a 4x4 pin matrix):

  ```
  [
    [:kc_no, :kc_01, :kc_02, :kc_03],
    [:kc_10, :kc_11, :kc_12, :kc_13],
    [:kc_20, :kc_21, :kc_no, :kc_23],
    [:kc_30, :kc_no, :kc_32, :kc_no]
  ]
  ```
  """
  def pin_matrix(physical_matrix, lines: line_pins, columns: column_pins) do
    line_pins = Utils.zip_with_index(line_pins)
    column_pins = Utils.zip_with_index(column_pins)

    for {{line_alias, _line_pin}, line_pin_index} <- line_pins do
      for {{column_alias, _column_pin}, column_pin_index} <- column_pins do
        case exists_in?(physical_matrix, {line_alias, column_alias}) do
          true ->
            Utils.kc(line_pin_index, column_pin_index)
          _ ->
            @disabled_keycode
        end
      end
    end
  end

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module}) do
    physical_matrix = Module.get_attribute(module, :physical_matrix)
    line_pins = Module.get_attribute(module, :line_pins)
                |> Enum.sort()
    column_pins = Module.get_attribute(module, :column_pins)
                  |> Enum.sort()

    physical_matrix_kc_xy = physical_matrix_kc_xy(
      physical_matrix, lines: line_pins, columns: column_pins)
      |> Enum.map(fn line ->
        Enum.map(line, fn keycode -> quoted_var(keycode) end)
      end)


    pin_matrix = pin_matrix(
      physical_matrix, lines: line_pins, columns: column_pins)

    quoted_pin_matrix = pin_matrix
                        |> Enum.map(fn line ->
                          Enum.map(line, fn keycode -> quoted_var(keycode) end)
                        end)

    Logger.debug(inspect(physical_matrix_kc_xy), label: "Physical matrix")
    Logger.debug(inspect(quoted_pin_matrix), label: "Pin matrix")

    quote do
      def map(unquote(physical_matrix_kc_xy)) do
        unquote(quoted_pin_matrix)
      end

      def pin_matrix() do
        unquote(pin_matrix)
      end
    end
  end

  defp quoted_var(@disabled_keycode), do: @disabled_keycode
  defp quoted_var(var) when is_atom(var), do: {var, [], Elixir}

  defp index_in_pin_list(pin_alias_to_find, pin_list) do
    Enum.find_index(
      pin_list,
      fn {pin_alias, _pin} ->
        pin_alias == pin_alias_to_find
      end
    )
    |> case do
      nil ->
        raise("Pin #{pin_alias_to_find} can't be found on pin list: #{inspect(pin_list)}")

      index ->
        index
    end
  end

  defp exists_in?(matrix, elem) do
    Enum.reduce_while(matrix, false, fn matrix_line, acc ->
      if elem in matrix_line do
        {:halt, true}
      else
        {:cont, acc}
      end
    end)
  end
end
