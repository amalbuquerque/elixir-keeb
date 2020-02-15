defmodule ElixirKeeb.LayoutTest do
  use ExUnit.Case
  alias ElixirKeeb.Usb.Keycodes
  alias ElixirKeeb.{Utils, KeycodeBehavior}

  @subject TestModule.First.Layout
  @matrix TestModule.First.Matrix
  @layer0 0
  @layer1 1

  describe "keycode/2 provided by the `use Layout`" do
    test "the `keycode/2` returns the expected keycode" do
      pin_matrix = @matrix.pin_matrix()

      # getting the layout in its physical disposition
      [layer0 | _rest] = @subject.all_layouts()

      # mapping the layout using the pin matrix
      layout_matrix = @matrix.map(layer0)

      pin_and_layout_matrices = Utils.zip_matrices(pin_matrix, layout_matrix)

      for line <- pin_and_layout_matrices do
        for {position, mapped_keycode} <- line do
          assert @subject.keycode(position, @layer0) == mapped_keycode
        end
      end
    end

    test "the `keycode/2` returns a %KeycodeBehavior{} expanded from a `toggle_layer(x)` and a `m(y)`" do
      [layer0 | _rest] = @subject.all_layouts()

      mapped_keycodes = @matrix.map(layer0)
                        |> List.flatten()

      keycode_behaviors = mapped_keycodes
                          |> Enum.filter(fn
                            %KeycodeBehavior{} -> true
                            _ -> false
                          end)

      assert [
        %KeycodeBehavior{
          action: :macro,
          keys: macro_keys
        },
        %KeycodeBehavior{
          action: :toggle,
          layer: 1
        }
      ] = keycode_behaviors

      # macro is "Elixir!"
      # 7 chars * 2 (pressed/released) + 2 Shift * 2 (press/released) = 18
      assert [
        {:kc_lshift, :pressed},
        {:kc_e, :pressed},
        {:kc_e, :released},
        {:kc_lshift, :released},
        {:kc_l, :pressed},
        {:kc_l, :released},
        {:kc_i, :pressed},
        {:kc_i, :released},
        {:kc_x, :pressed},
        {:kc_x, :released},
        {:kc_i, :pressed},
        {:kc_i, :released},
        {:kc_r, :pressed},
        {:kc_r, :released},
        {:kc_lshift, :pressed},
        {:kc_1, :pressed},
        {:kc_1, :released},
        {:kc_lshift, :released},
      ] == macro_keys
    end

    test "the `keycode/2` for the layer 1 returns the expected keycode, even for transparent keycodes" do
      pin_matrix = @matrix.pin_matrix()

      # getting the layout in its physical disposition
      [_layer0, layer1, _layer2] = @subject.all_layouts()

      # mapping the layout using the pin matrix
      layout_matrix = @matrix.map(layer1)

      pin_and_layout_matrices = Utils.zip_matrices(pin_matrix, layout_matrix)

      for line <- pin_and_layout_matrices do
        for {position, mapped_keycode} <- line do
          case Keycodes.is_transparent?(mapped_keycode) do
            true ->
              assert @subject.keycode(position, @layer1) == @subject.keycode(position, @layer0)
            _ ->
              assert @subject.keycode(position, @layer1) == mapped_keycode
          end
        end
      end
    end

    test "the `keycode/2` for the layer 1 returns the expected keycode for the transparent keycodes positions" do
      # :kc_11 is the pin position (line 1, column 1) of :kc_k on layer 0
      assert :kc_k == @subject.keycode(:kc_11, 1)

      # :kc_30 is the pin position (line 3, column 0) of toggle_layer(1) on layer 0
      assert %KeycodeBehavior{
        action: :toggle,
        layer: 1} == @subject.keycode(:kc_30, 1)
    end

    test "the `keycode/2` for the layer 2 returns the expected keycode for the transparent keycodes positions" do
      # :kc_11 is the pin position (line 1, column 1) of :kc_v on layer 2
      # (this position isn't transparent on layer 2)
      assert :kc_v == @subject.keycode(:kc_11, 2)

      # :kc_30 is the pin position (line 3, column 0) of toggle_layer(1) on layer 0
      assert %KeycodeBehavior{
        action: :toggle,
        layer: 1} == @subject.keycode(:kc_30, 2)

      # :kc_20 is the pin position (line 2, column 0) of :kc_9 on layer 1
      assert :kc_9 == @subject.keycode(:kc_20, 2)
    end
  end
end
