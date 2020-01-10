defmodule ElixirKeeb.Layout do
  @moduledoc """
  """

  require Logger
  alias ElixirKeeb.Utils

  defmacro __using__(matrix: matrix_module) do
    %Macro.Env{module: caller_module} = __CALLER__
    Module.put_attribute(caller_module, :matrix_module, matrix_module)

    quote do
      import unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module} = env) do
    layouts = Module.get_attribute(module, :layouts)
    matrix_module = Module.get_attribute(module, :matrix_module)
                    |> Macro.expand(env)

    IO.puts(inspect(layouts))
    IO.puts(inspect(matrix_module))

    pin_matrix = matrix_module.pin_matrix()

    layouts
    |> Enum.map(fn layout -> matrix_module.map(layout) end)
    |> Enum.zip(0..(length(layouts) - 1))
    |> Enum.map(fn {layout, layer_index} ->
      keycode_functions_for_layer(layout, pin_matrix, layer_index)
    end)
    |> List.flatten()
    |> Kernel.++([catch_all_keycode_function()])
    |> wrap_in_a_block()
  end

  defp keycode_functions_for_layer(layout_matrix, pin_matrix, layer) do
    layout_and_pin_matrices = Utils.zip_matrices(layout_matrix, pin_matrix)

    for line <- layout_and_pin_matrices do
      for {layout_keycode, kc_xy} <- line do
        keycode_function(kc_xy, layer, layout_keycode)
      end
    end
    |> List.flatten()
  end

  defp keycode_function(kc_xy, layer, keycode) do
    quote do
      def keycode(unquote(kc_xy), unquote(layer)) do
        unquote(keycode)
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
