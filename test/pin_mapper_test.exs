defmodule ElixirKeeb.PinMapperTest do
  use ExUnit.Case

  @subject TestModule.Matrix

  @physical_layout [
    [:kc_a, :kc_b, :kc_c, :kc_d],
    [:kc_e, :kc_f, :kc_g, :kc_h],
    [:kc_i, :kc_j, :kc_k, :kc_l]
  ]

  describe "pin_matrix/0 provided by the `use PinMapper`" do
    test "it returns a 4x4 matrix (since we have 4 line pins and 4 column pins)" do
      result = @subject.pin_matrix()

      assert length(result) == 4
      Enum.each(result, fn line -> assert length(line) == 4 end)
    end

    test "it returns the expected outcome using the kc_xy format" do
      expected = [
        [:kc_no,  :kc_01,  :kc_02,  :kc_03],
        [:kc_10,  :kc_11,  :kc_12,  :kc_13],
        [:kc_20,  :kc_21,  :kc_no,  :kc_23],
        [:kc_30,  :kc_no,  :kc_32,  :kc_no],
      ]

      assert expected ==  @subject.pin_matrix()
    end
  end

  describe "map/1 provided by the `use PinMapper`" do
    test "it returns a 4x4 matrix (since we have 4 line pins and 4 column pins)" do
      result = @subject.map(@physical_layout)

      assert length(result) == 4
      Enum.each(result, fn line -> assert length(line) == 4 end)
    end

    # it maps each physical layout position to the corresponding
    # row+col pin
    test "it returns the expected outcome using the kc_keycode format" do
      expected = [
        [:kc_no, :kc_a,   :kc_f,   :kc_c],
        [:kc_b,  :kc_k,   :kc_d,   :kc_e],
        [:kc_i,  :kc_j,   :kc_no,  :kc_h],
        [:kc_l,  :kc_no,  :kc_g,   :kc_no],
      ]

      assert expected == @subject.map(@physical_layout)
    end
  end
end
