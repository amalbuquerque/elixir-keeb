defmodule ElixirKeeb.Layout do
  @moduledoc """
  """

  require Logger
  alias ElixirKeeb.{Utils, KeycodeBehavior}
  alias ElixirKeeb.Usb.Keycodes
  import ElixirKeeb.Usb.Keycodes, only: [transparent?: 1]

  defmacro toggle_layer(layer) when is_integer(layer) do
    quote do
      %KeycodeBehavior{
        action: :toggle,
        layer: unquote(layer)
      }
    end
  end

  defmacro __using__(matrix: matrix_module) do
    %Macro.Env{module: caller_module} = __CALLER__
    Module.put_attribute(caller_module, :matrix_module, matrix_module)

    quote do
      import unquote(__MODULE__)
      require unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module} = env) do
    layouts = Module.get_attribute(module, :layouts)
    matrix_module = Module.get_attribute(module, :matrix_module)
                    |> Macro.expand(env)

    Logger.debug(inspect(layouts), label: "Layouts it received via @layouts")
    Logger.debug(inspect(matrix_module), label: "Matrix module it received via @matrix_module")

    pin_matrix = matrix_module.pin_matrix()

    layout_matrices = Enum.map(layouts, &matrix_module.map/1)

    result = layout_matrices
             |> Enum.zip(0..(length(layouts) - 1))
             |> Enum.map(fn {_layout_matrix, layer_index} ->
               keycode_functions_for_layer(layout_matrices, layer_index, pin_matrix)
             end)
             |> List.flatten()
             |> Enum.uniq()
             |> Kernel.++([
               catch_all_keycode_function(),
               all_layouts_function()
             ])
             |> wrap_in_a_block()

    Logger.debug(inspect(result), label: "Layout macro module result")

    result
  end

  defp all_layouts_function() do
    quote do
      def all_layouts() do
        @layouts
      end
    end
  end

  def keycode_functions_for_layer(layout_matrices, layer_index, pin_matrix) do
    layout_matrix = Enum.at(layout_matrices, layer_index)
    layout_and_pin_matrices = Utils.zip_matrices(layout_matrix, pin_matrix)

    for {line, line_index} <- Utils.zip_with_index(layout_and_pin_matrices) do
      for {{layout_keycode, kc_xy}, column_index} <- Utils.zip_with_index(line) do
        layout_keycode = actual_keycode(
          layout_keycode, layout_matrices, layer_index, line_index, column_index)

        keycode_function(kc_xy, layer_index, layout_keycode)
      end
    end
    |> List.flatten()
  end

  def actual_keycode(
    current_keycode, _layout_matrices, _layer_index, _line_index, _column_index) when not transparent?(current_keycode), do: current_keycode

  def actual_keycode(current_keycode, layout_matrices, layer_index, line_index, column_index) when transparent?(current_keycode) do
    (layer_index-1)..0
    |> Enum.reduce_while(current_keycode, fn layer, _acc ->
      layout = Enum.at(layout_matrices, layer)
      keycode = Utils.matrix_at(layout, line_index, column_index)

      case Keycodes.is_transparent?(keycode) do
        true ->
          {:cont, current_keycode}
        _ ->
          {:halt, keycode}
      end
    end)
  end

  defp keycode_function(kc_xy, layer, keycode) when is_atom(keycode) do
    quote do
      def keycode(unquote(kc_xy), unquote(layer)) do
        unquote(keycode)
      end
    end
  end

  defp keycode_function(kc_xy, layer, keycode) do
    escaped_keycode = Macro.escape(keycode)

    quote do
      def keycode(unquote(kc_xy), unquote(layer)) do
        unquote(escaped_keycode)
      end
    end
  end

  defp catch_all_keycode_function() do
    keycode_function({:_, [], Elixir}, {:_, [], Elixir}, :kc_no)
  end

  defp wrap_in_a_block(statements) do
    {:__block__, [], statements}
  end
end
