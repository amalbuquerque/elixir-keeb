defmodule TestModule.Canon.Matrix do
  use ElixirKeeb.PinMapper

  @physical_matrix [
    [A6: :B7, A3: :B4, A4: :B4, A5: :B4, A6: :B4, A7: :B4, A8: :B4, A1: :B5, A2: :B5, A3: :B5, A4: :B5, A3: :B6, A4: :B6, A2: :B7, A3: :B7],
    [A7: :B7, A1: :B3, A7: :B3, A5: :B1, A2: :B3, A4: :B3, A1: :B4, A5: :B3, A1: :B2, A7: :B2, A8: :B2, A2: :B6, A4: :B7, A5: :B7],
    [A9: :B9, A1: :B1, A3: :B3, A4: :B1, A6: :B1, A7: :B1, A8: :B1, A2: :B2, A3: :B2, A4: :B2, A7: :B5, A6: :B5, A5: :B6, A6: :B6],
    [A9: :BA, A2: :B4, A8: :B3, A3: :B1, A6: :B3, A2: :B1, A6: :B2, A5: :B2, A5: :B5, A8: :B5, A1: :B6, A9: :BA],
    [A8: :B8, A8: :B6, A1: :B7]
  ]

  @line_pins [
    # {human-readable name, pin}
    {:AB, 14},
    {:AA, 15},
    {:A9, 18},
    {:A8, 23},
    {:A7, 24},
    {:A6, 25},
    {:A5, 8},
    {:A4, 7},
    {:A3, 12},
    {:A2, 16},
    {:A1, 20}
  ]

  @column_pins [
    # {human-readable name, pin}
    {:BA, 4},
    {:B9, 17},
    {:B8, 27},
    {:B7, 22},
    {:B6, 10},
    {:B5, 9},
    {:B4, 11},
    {:B3, 5},
    {:B2, 6},
    {:B1, 13}
  ]
end

defmodule TestModule.Canon.Layout do
  use ElixirKeeb.Layout, matrix: TestModule.Canon.Matrix

  @layouts [
    [ # layer 0
      [:kc_escape, :kc_1, :kc_2, :kc_3, :kc_4, :kc_5, :kc_6, :kc_7, :kc_8, :kc_9, :kc_0, :kc_equal, :kc_slash, :kc_delete, :kc_bspace],
      [:kc_tab, :kc_q, :kc_w, :kc_e, :kc_r, :kc_t, :kc_y, :kc_u, :kc_i, :kc_o, :kc_p, :kc_lbracket, :kc_rbracket, :kc_bslash],
      [:kc_lctrl, :kc_a, :kc_s, :kc_d, :kc_f, :kc_g, :kc_h, :kc_j, :kc_k, :kc_l, :kc_scolon, :kc_quote, :kc_lgui, :kc_enter],
      [:kc_lshift, :kc_z, :kc_x, :kc_c, :kc_v, :kc_b, :kc_n, :kc_m, :kc_comma, :kc_dot, :kc_grave, :kc_lshift],
      [:kc_lalt, :kc_space, :kc_ralt]
    ]
  ]
end
