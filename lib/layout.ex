defmodule ElixirKeeb.Layout do
  @moduledoc """
  """

  require Logger
  alias ElixirKeeb.Structs.KeycodeBehavior
  alias ElixirKeeb.{
    Utils,
    Macros
  }
  import ElixirKeeb.Usb.Keycodes, only: [transparent?: 1, normal?: 1, modifier?: 1]

  defmacro toggle_layer(layer) when is_integer(layer) do
    quote do
      %KeycodeBehavior{
        action: :toggle,
        layer: unquote(layer)
      }
    end
  end

  defmacro lock_layer(layer) when is_integer(layer) do
    quote do
      %KeycodeBehavior{
        action: :lock,
        layer: unquote(layer)
      }
    end
  end

  defmacro tap_or_toggle(tap, toggle)
  when normal?(tap) and (normal?(toggle) or modifier?(toggle) or is_integer(toggle)) do
    quote do
      %KeycodeBehavior{
        action: :tap_or_toggle,
        tap_or_toggle: %{
          tap: unquote(tap),
          toggle: unquote(toggle),
          type: :regular
        }
      }
    end
  end

  defmacro __using__(matrix: matrix_module) do
    %Macro.Env{module: caller_module} = __CALLER__
    Module.put_attribute(caller_module, :matrix_module, matrix_module)

    quote do
      import unquote(__MODULE__)
      require unquote(__MODULE__)
      import ElixirKeeb.Macros, only: [m: 1, record: 1, replay: 1]
      require ElixirKeeb.Macros

      @behaviour ElixirKeeb.Layout.Behaviour

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module} = env) do
    layouts = Module.get_attribute(module, :layouts)
    macros = Module.get_attribute(module, :macros) || []
    matrix_module = Module.get_attribute(module, :matrix_module)
                    |> Macro.expand(env)

    Logger.debug(inspect(layouts), label: "Layouts it received via @layouts")
    Logger.debug(inspect(macros), label: "Macros module it received via @macros")
    Logger.debug(inspect(matrix_module), label: "Matrix module it received via @matrix_module")

    pin_matrix = matrix_module.pin_matrix()
    physical_matrix_kc_xy = matrix_module.physical_matrix_kc_xy()

    keycode_functions = layouts
                        |> Enum.map(&matrix_module.map/1)
                        |> Enum.zip(0..(length(layouts) - 1))
                        |> Enum.map(fn {layout_matrix, layer_index} ->
                          keycode_functions_for_layer(layout_matrix, layer_index, pin_matrix)
                        end)
                        |> List.flatten()
                        |> Enum.uniq()
                        |> Kernel.++([catch_all_keycode_function()])

    keycode_by_physical_position_functions = layouts
                        |> Utils.zip_with_index()
                        |> Enum.map(fn {layout, layer_index} ->
                          keycode_by_physical_position_functions_for_layer(
                            layout, layer_index, physical_matrix_kc_xy)
                        end)
                        |> List.flatten()
                        |> Enum.uniq()

    macros_functions = macros
                       |> Utils.zip_with_index()
                       |> Enum.map(fn {macro_content, index} -> Macros.macro_function(index, macro_content) end)

    result = keycode_functions
             |> Kernel.++(keycode_by_physical_position_functions)
             |> Kernel.++(macros_functions)
             |> Kernel.++([all_layouts_function()])
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

  def keycode_functions_for_layer(layout_matrix, layer_index, pin_matrix) do
    layout_and_pin_matrices = Utils.zip_matrices(layout_matrix, pin_matrix)

    for line <- layout_and_pin_matrices do
      for {layout_keycode, kc_xy} <- line do
        keycode_function(kc_xy, layer_index, layout_keycode)
      end
    end
    |> List.flatten()
  end

  def keycode_by_physical_position_functions_for_layer(layout, layer_index, physical_matrix_kc_xy) do
    layout_and_physical_matrix_kc_xy = Utils.zip_matrices(layout, physical_matrix_kc_xy)

    for {line, row_index} <- Utils.zip_with_index(layout_and_physical_matrix_kc_xy) do
      for {{_layout_keycode, physical_matrix_kc_xy}, col_index} <- Utils.zip_with_index(line) do
        keycode_by_physical_position_function(row_index, col_index, physical_matrix_kc_xy, layer_index)
      end
    end
    |> List.flatten()
  end

  defp keycode_by_physical_position_function(row_index, col_index, kc_xy, layer) do
    quote do
      def keycode_by_physical_position(unquote(row_index), unquote(col_index), unquote(layer)) do
        keycode(unquote(kc_xy), unquote(layer))
      end
    end
  end

  defp keycode_function(kc_xy, layer, keycode) when transparent?(keycode) and layer > 0 do
    quote do
      @impl true
      def keycode(unquote(kc_xy), unquote(layer)) do
        # if transparent, we just call the `keycode/2` for the previous layer
        keycode(unquote(kc_xy), unquote(layer-1))
      end
    end
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
