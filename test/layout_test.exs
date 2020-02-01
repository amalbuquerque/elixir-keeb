defmodule ElixirKeeb.LayoutTest do
  use ExUnit.Case
  alias ElixirKeeb.{Utils, KeycodeBehavior}

  @subject TestModule.First.Layout
  @matrix TestModule.First.Matrix
  @layer0 0

  describe "keycode/2 provided by the `use Layout`" do
    test "the `keycode/2` returns the expected keycode" do
      pin_matrix = @matrix.pin_matrix()

      # getting the layout in its physical disposition
      [layer0] = @subject.all_layouts()

      # mapping the layout using the pin matrix
      layout_matrix = @matrix.map(layer0)

      pin_and_layout_matrices = Utils.zip_matrices(pin_matrix, layout_matrix)

      for line <- pin_and_layout_matrices do
        for {position, mapped_keycode} <- line do
          assert @subject.keycode(position, @layer0) == mapped_keycode
        end
      end
    end

    test "the `keycode/2` returns a %KeycodeBehavior{} expanded from a `toggle_layer(x)`" do
      [layer0] = @subject.all_layouts()
      mapped_keycodes = @matrix.map(layer0)
                        |> List.flatten()

      keycode_behaviors = mapped_keycodes
                          |> Enum.filter(fn
                            %KeycodeBehavior{} -> true
                            _ -> false
                          end)

      assert [%KeycodeBehavior{
        action: :toggle,
        layer: 1}] = keycode_behaviors
    end
  end
end
