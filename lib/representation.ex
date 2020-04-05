defmodule ElixirKeeb.Representation do
  @moduledoc """
  This module exists to get a string representation that
  can be used by the `simple_keyboard` Javascript library
  in the web dashboard provided by the `poncho` `elixir_keeb_ui`
  project.
  """
  alias ElixirKeeb.Utils

  @doc """
  This function expects a module that is using the
  `ElixirKeeb.Layout` module, since it relies on two functions
  provided by the usage of the module: `all_layouts/0` and
  `keycode_by_physical_position/3`. It will return a string
  representation of the keyboard layout that will be consumed
  by the `simple_keyboard` Javascript library.
  """
  def to_dashboard(keeb_module) do
    layers = keeb_module.all_layouts()

    dashboard_representation = layers
                               |> Utils.zip_with_index()
                               |> Enum.map(&layer_to_dashboard(&1, keeb_module))

    # the first row will be used to indicate
    # which layer is currently active
    first_row = Keyword.keys(dashboard_representation)
                |> Enum.map(fn layer -> "{#{layer}}" end)
                |> Enum.join(" ")

    dashboard_representation
    |> Enum.map(fn {layer_key, layer_representation} ->
      {layer_key, [first_row | layer_representation]}
    end)
  end

  defp layer_to_dashboard({layer, layer_index}, keeb_module) do
    layer_representation =
      layer
      |> Utils.zip_with_index()
      |> Enum.map(fn {row, row_index} ->
        row
        |> Utils.zip_with_index()
        |> Enum.map(fn {_keycode, col_index} ->
          keeb_module.keycode_by_physical_position(
            row_index, col_index, layer_index)
            |> string_representation()
        end)
        |> Enum.join(" ")
      end)

    layer_representation_with_key(
      layer_index, layer_representation)
end

  defp layer_representation_with_key(0, layer_representation) do
    {:default, layer_representation}
  end

  defp layer_representation_with_key(index, layer_representation) do
    {String.to_atom("layer_#{index}"), layer_representation}
  end

  defp string_representation(keycode) when is_atom(keycode) do
    to_string(keycode) |> String.replace("kc_", "")
  end

  defp string_representation(%ElixirKeeb.KeycodeBehavior{
    action: action,
    layer: layer
  }) when action in [:toggle, :lock] do
    "{layer_#{layer}}"
  end

  defp string_representation(%ElixirKeeb.KeycodeBehavior{
    action: :macro,
    keys: keys
  }) do
    # TODO: Change to use the macro ID instead
    # of macro keys
    keys = keys
           |> Keyword.keys()
           |> Enum.map(&to_string/1)
           |> Enum.uniq()
           |> Enum.map(fn "kc_" <> key -> key end)
           |> Enum.join("")

    "macro_#{keys}"
  end
end
