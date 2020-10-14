defmodule ElixirKeeb.Representation do
  alias ElixirKeeb.Structs.KeycodeBehavior

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
    |> Enum.into(%{})
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

  def string_representation(keycode) when is_atom(keycode) do
    to_string(keycode) |> String.replace("kc_", "")
  end

  def string_representation(%KeycodeBehavior{
    action: action,
    layer: layer
  }) when action in [:toggle, :lock] do
    "{layer_#{layer}}"
  end

  def string_representation(%KeycodeBehavior{
    action: :macro,
    identifier: macro_id,
  }) do
    "macro_#{macro_id}"
  end

  def string_representation(%KeycodeBehavior{
    action: :record,
    identifier: recording_id,
  }) do
    "record_#{recording_id}"
  end

  def string_representation(%KeycodeBehavior{
    action: :replay,
    identifier: recording_id,
  }) do
    "replay_#{recording_id}"
  end

  def string_representation(%KeycodeBehavior{
    action: :tap_or_toggle,
    tap_or_toggle: %{
      tap: tap_key,
      toggle: toggle_key
    },
  }) do
    "tap_or_toggle_#{tap_key}_#{toggle_key}"
  end
end
