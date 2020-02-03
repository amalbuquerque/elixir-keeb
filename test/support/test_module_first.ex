defmodule TestModule.First.Matrix do
  use ElixirKeeb.PinMapper

  @physical_matrix [
    [P1: :P4, P3: :P2, P1: :P7, P3: :P6],
    [P3: :P7, P1: :P6, P8: :P6, P5: :P7],
    [P5: :P2, P5: :P4, P3: :P4, P8: :P2]
  ]

  @line_pins [P1: 1, P3: 3, P5: 5, P8: 8]
  @column_pins [P2: 2, P4: 4, P6: 6, P7: 7]
end

defmodule TestModule.First.Layout do
  use ElixirKeeb.Layout, matrix: TestModule.First.Matrix

  @layouts [
    [ # layer 0
      [:kc_a, :kc_b, :kc_c, :kc_d          ],
      [:kc_e, :kc_f, :kc_g, :kc_h          ],
      [:kc_i, :kc_j, :kc_k, toggle_layer(1)]
    ],
    [ # layer 1
      [:kc_1, :kc_2, :kc_3, :kc_4],
      [:kc_5, :kc_6, :kc_7, :kc_8],
      [:kc_9, :kc_0, :____, :____]
    ],
    [ # layer 2
      [:kc_l, :kc_m, :kc_n, :kc_o],
      [:kc_p, :kc_q, :kc_r, :kc_s],
      [:____, :kc_u, :kc_v, :____]
    ],
  ]
end
