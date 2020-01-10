defmodule TestModule.Matrix do
  use ElixirKeeb.PinMapper

  @physical_matrix [
    [P1: :P4, P3: :P2, P1: :P7, P3: :P6],
    [P3: :P7, P1: :P6, P8: :P6, P5: :P7],
    [P5: :P2, P5: :P4, P3: :P4, P8: :P2]
  ]

  @line_pins [P1: 1, P3: 3, P5: 5, P8: 8]
  @column_pins [P2: 2, P4: 4, P6: 6, P7: 7]
end

defmodule TestModule.Layout do
  use ElixirKeeb.Layout, matrix: TestModule.Matrix

  @layouts [
    [ # layer 0
      [:a, :b, :c, :d],
      [:e, :f, :g, :h],
      [:i, :j, :k, :l]
    ],
  ]
end


  # physical_matrix = [
  #   [P1: :P4, P3: :P2, P1: :P7, P3: :P6],
  #   [P3: :P7, P1: :P6, P8: :P6, P5: :P7],
  #   [P5: :P2, P5: :P4, P3: :P4, P8: :P2]
  # ]

  # line_pins = [P1: 1, P3: 3, P5: 5, P8: 8]
  # column_pins = [P2: 2, P4: 4, P6: 6, P7: 7]
