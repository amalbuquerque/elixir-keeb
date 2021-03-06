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

defmodule TestModule.First.Macros do
  def xpto(state) do

    {"Hello from custom macro", state}
  end
end

defmodule TestModule.First.Layout do
  use ElixirKeeb.Layout, matrix: TestModule.First.Matrix

  @macros [
    # macro 0
    [
      {:kc_lshift, :pressed},
      :kc_e,
      {:kc_lshift, :released},
      :kc_l,
      :kc_i,
      :kc_x,
      :kc_i,
      :kc_r,
      {:kc_lshift, :pressed},
      :kc_1,
      {:kc_lshift, :released},
    ],
    # macro 1
    [
      {"lshift", :pressed},
      "e",
      {"lshift", :released},
      "l",
      "i",
      "x",
      "i",
      "r",
      {"lshift", :pressed},
      "1",
      {"lshift", :released},
    ],
    # macro 2
    &TestModule.First.Macros.xpto/1
  ]

  @layouts [
    [ # layer 0
      [:kc_a, :kc_b,           :kc_c, m(0)           ],
      [:kc_e, :kc_f,           :kc_g, m(1)           ],
      [:kc_i, toggle_layer(2), :kc_k, toggle_layer(1)]
    ],
    [ # layer 1
      [:kc_1,     :kc_2, :kc_3, :kc_4],
      [record(1), :kc_6, :kc_7, :kc_8],
      [:kc_9,     :kc_0, :____, :____]
    ],
    [ # layer 2
      [:kc_l,     :kc_m, :kc_n, :kc_o],
      [replay(1), :kc_q, :kc_r, :kc_s],
      [:____,     m(2),  :kc_v, :____]
    ],
  ]
end
