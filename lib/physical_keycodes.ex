defmodule ElixirKeeb.PhysicalKeycodes do
  alias ElixirKeeb.Utils

  @max_index 35

  @kc_xy_keycode_indexes 0..@max_index
  |> Enum.flat_map(fn line_index ->
    Enum.map(0..@max_index, fn col_index -> {line_index, col_index} end)
    end)

  @kc_xy_keycodes @kc_xy_keycode_indexes
  |> Enum.map(fn {line_index, col_index} ->
    Utils.kc(line_index, col_index)
  end)

  @kc_xy_keycodes
  |> Enum.map(fn kc_xy ->
    def is_kc_xy?(unquote(kc_xy)), do: true
  end)

  def is_kc_xy?(_), do: false

  def debug_all_keycodes, do: @kc_xy_keycodes

  @half_kc_xy_keycodes 648

  # splitting the keycodes list due to a compiler bug
  # https://github.com/elixir-lang/elixir/issues/10114
  @kc_xy_keycodes_1st_half Enum.take(@kc_xy_keycodes, @half_kc_xy_keycodes)
  @kc_xy_keycodes_2nd_half Enum.take(@kc_xy_keycodes, -@half_kc_xy_keycodes)

  defguard kc_xy?(value) when value in @kc_xy_keycodes_1st_half or value in @kc_xy_keycodes_2nd_half
end
