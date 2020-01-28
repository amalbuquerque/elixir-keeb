defmodule ElixirKeeb.PinMapperTest do
  use ExUnit.Case

  describe "pin_matrix/0 provided by the `use PinMapper` (simple case)" do
    setup :simple_subject

    test "it returns a 4x4 matrix (since we have 4 line pins and 4 column pins)", %{subject: subject} do
      result = subject.pin_matrix()

      assert length(result) == 4
      Enum.each(result, fn line -> assert length(line) == 4 end)
    end

    test "it returns the expected outcome using the kc_xy format", %{subject: subject} do
      expected = [
        [:kc_no,  :kc_01,  :kc_02,  :kc_03],
        [:kc_10,  :kc_11,  :kc_12,  :kc_13],
        [:kc_20,  :kc_21,  :kc_no,  :kc_23],
        [:kc_30,  :kc_no,  :kc_32,  :kc_no],
      ]

      assert expected ==  subject.pin_matrix()
    end
  end

  describe "map/1 provided by the `use PinMapper` (simple case)" do
    setup :simple_subject

    test "it returns a 4x4 matrix (since we have 4 line pins and 4 column pins)", %{subject: subject, physical_layout: physical_layout} do
      result = subject.map(physical_layout)

      assert length(result) == 4
      Enum.each(result, fn line -> assert length(line) == 4 end)
    end

    # it maps each physical layout position to the corresponding row+col pin
    test "it returns the expected outcome using the kc_keycode format", %{subject: subject, physical_layout: physical_layout} do
      expected = [
        [:kc_no, :kc_a,   :kc_f,   :kc_c],
        [:kc_b,  :kc_k,   :kc_d,   :kc_e],
        [:kc_i,  :kc_j,   :kc_no,  :kc_h],
        [:kc_l,  :kc_no,  :kc_g,   :kc_no],
      ]

      assert expected == subject.map(physical_layout)
    end
  end

  describe "pin_matrix/0 provided by the `use PinMapper` (complex case)" do
    setup :complex_subject

    test "it returns a 11x10 matrix (since we have 11 line pins and 10 column pins)", %{subject: subject} do
      result = subject.pin_matrix()

      assert length(result) == 11
      Enum.each(result, fn line -> assert length(line) == 10 end)
    end

    test "it returns the expected outcome using the kc_xy format", %{subject: subject} do
      expected = [
        [:kc_00, :kc_01, :kc_02, :kc_03, :kc_04, :kc_05, :kc_06, :kc_no, :kc_no, :kc_no],
        [:kc_10, :kc_11, :kc_12, :kc_13, :kc_14, :kc_15, :kc_16, :kc_no, :kc_no, :kc_no],
        [:kc_20, :kc_21, :kc_22, :kc_23, :kc_24, :kc_25, :kc_26, :kc_no, :kc_no, :kc_no],
        [:kc_30, :kc_31, :kc_32, :kc_33, :kc_34, :kc_35, :kc_36, :kc_no, :kc_no, :kc_no],
        [:kc_40, :kc_41, :kc_42, :kc_43, :kc_44, :kc_45, :kc_46, :kc_no, :kc_no, :kc_no],
        [:kc_50, :kc_51, :kc_52, :kc_53, :kc_54, :kc_55, :kc_56, :kc_no, :kc_no, :kc_no],
        [:kc_60, :kc_61, :kc_62, :kc_63, :kc_64, :kc_no, :kc_66, :kc_no, :kc_no, :kc_no],
        [:kc_70, :kc_71, :kc_72, :kc_73, :kc_74, :kc_75, :kc_no, :kc_77, :kc_no, :kc_no],
        [:kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_88, :kc_89],
        [:kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no],
        [:kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no]
      ]

      assert expected ==  subject.pin_matrix()
    end
  end

  describe "map/1 provided by the `use PinMapper` (complex case)" do
    setup :complex_subject

    test "it returns a 11x10 matrix (since we have 11 line pins and 10 column pins)", %{subject: subject, physical_layout: physical_layout} do
      result = subject.map(physical_layout)

      assert length(result) == 11
      Enum.each(result, fn line -> assert length(line) == 10 end)
    end

    # it maps each physical layout position to the corresponding row+col pin
    test "it returns the expected outcome using the kc_keycode format", %{subject: subject, physical_layout: physical_layout} do
      expected = [
        [:kc_a, :kc_i, :kc_q, :kc_y, :kc_7, :kc_grave, :kc_ralt, :kc_no, :kc_no, :kc_no],
        [:kc_b, :kc_j, :kc_r, :kc_z, :kc_8, :kc_lbracket, :kc_delete, :kc_no, :kc_no, :kc_no],
        [:kc_c, :kc_k, :kc_s, :kc_1, :kc_9, :kc_equal, :kc_bspace, :kc_no, :kc_no, :kc_no],
        [:kc_d, :kc_l, :kc_t, :kc_2, :kc_0, :kc_slash, :kc_rbracket, :kc_no, :kc_no, :kc_no],
        [:kc_e, :kc_m, :kc_u, :kc_3, :kc_comma, :kc_lgui, :kc_bslash, :kc_no, :kc_no, :kc_no],
        [:kc_f, :kc_n, :kc_v, :kc_4, :kc_quote, :kc_enter, :kc_escape, :kc_no, :kc_no, :kc_no],
        [:kc_g, :kc_o, :kc_w, :kc_5, :kc_scolon, :kc_no, :kc_tab, :kc_no, :kc_no, :kc_no],
        [:kc_h, :kc_p, :kc_x, :kc_6, :kc_dot, :kc_space, :kc_no, :kc_lalt, :kc_no, :kc_no],
        [:kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_lctrl, :kc_lshift],
        [:kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no],
        [:kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no, :kc_no]
      ]

      assert expected == subject.map(physical_layout)
    end

    test "it maps the Tab to the expected position (A6 B6)", %{subject: subject, physical_layout: physical_layout} do
      result = subject.map(physical_layout)

      assert result |> Enum.at(6) |> Enum.at(6) == :kc_tab
    end

    test "it maps the 3 to the expected position (A4 B3)", %{subject: subject, physical_layout: physical_layout} do
      result = subject.map(physical_layout)

      assert result |> Enum.at(4) |> Enum.at(3) == :kc_3
    end
  end

  defp simple_subject(_context) do
    physical_layout = [
      [:kc_a, :kc_b, :kc_c, :kc_d],
      [:kc_e, :kc_f, :kc_g, :kc_h],
      [:kc_i, :kc_j, :kc_k, :kc_l]
    ]

    {:ok,
      subject: TestModule.First.Matrix, physical_layout: physical_layout}
  end

  defp complex_subject(_context) do
    physical_layout = [
      [:kc_escape, :kc_1, :kc_2, :kc_3, :kc_4, :kc_5, :kc_6, :kc_7, :kc_8, :kc_9, :kc_0, :kc_equal, :kc_slash, :kc_delete, :kc_bspace],
      [:kc_tab, :kc_q, :kc_w, :kc_e, :kc_r, :kc_t, :kc_y, :kc_u, :kc_i, :kc_o, :kc_p, :kc_lbracket, :kc_rbracket, :kc_bslash],
      [:kc_lctrl, :kc_a, :kc_s, :kc_d, :kc_f, :kc_g, :kc_h, :kc_j, :kc_k, :kc_l, :kc_scolon, :kc_quote, :kc_lgui, :kc_enter],
      [:kc_lshift, :kc_z, :kc_x, :kc_c, :kc_v, :kc_b, :kc_n, :kc_m, :kc_comma, :kc_dot, :kc_grave, :kc_lshift],
      [:kc_lalt, :kc_space, :kc_ralt]
    ]

    {:ok,
      subject: TestModule.Canon.Matrix, physical_layout: physical_layout}
  end
end
