defmodule ElixirKeeb.CanonTypewriter.Matrix do
  use ElixirKeeb.PinMapper

  # TODO: allow a streamlined "a6_b7" format instead
  @physical_matrix [
    [A6: :B7, A3: :B4, A4: :B4, A5: :B4, A6: :B4, A7: :B4, A8: :B4, A1: :B5, A2: :B5, A3: :B5, A4: :B5, A3: :B6, A4: :B6, A2: :B7, A3: :B7],
    [A7: :B7, A1: :B3, A7: :B3, A5: :B1, A2: :B3, A4: :B3, A1: :B4, A5: :B3, A1: :B2, A7: :B2, A8: :B2, A2: :B6, A4: :B7, A5: :B7],
    [A9: :B9, A1: :B1, A3: :B3, A4: :B1, A6: :B1, A7: :B1, A8: :B1, A2: :B2, A3: :B2, A4: :B2, A7: :B5, A6: :B5, A5: :B6, A6: :B6],
    [A9: :BA, A2: :B4, A8: :B3, A3: :B1, A6: :B3, A2: :B1, A6: :B2, A5: :B2, A5: :B5, A8: :B5, A1: :B6, A9: :BA],
    [A8: :B8, A8: :B6, A1: :B7]
  ]

  @line_pins Application.get_env(:elixir_keeb, :line_pins)
  @column_pins Application.get_env(:elixir_keeb, :column_pins)
end

defmodule ElixirKeeb.CanonTypewriter.Macros do
  def network_info_macro(state) do
    :ok = VintageNet.info()

    all_interfaces = VintageNet.all_interfaces()
    current_config = VintageNet.get_configuration("wlan0")

    message = "VintageNet.info! Interfaces: #{inspect(all_interfaces)}, Current config: #{inspect(current_config)}"

    {message, state}
  end

  def configure_network_macro(state) do
    [{"wlan0", config} | _] = Application.get_env(:vintage_net, :config)

    result = VintageNet.configure("wlan0", config)

    message = "Just configured with: #{inspect(config)}. Result: #{inspect(result)}"

    {message, state}
  end
end

defmodule ElixirKeeb.CanonTypewriter.Layout do
  use ElixirKeeb.Layout, matrix: ElixirKeeb.CanonTypewriter.Matrix

  @macros [
    # macro 0
    [:kc_a, :kc_b, :kc_c],
    # macro 1
    "xyz" |> String.graphemes(),
    # macro 2
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
    # macro 3
    "Hello, world!",
    # macro 4
    &ElixirKeeb.CanonTypewriter.Macros.network_info_macro/1,
    # macro 5
    &ElixirKeeb.CanonTypewriter.Macros.configure_network_macro/1,
  ]

  @layouts [
    [ # layer 0
      [:kc_escape, :kc_1, :kc_2, :kc_3, :kc_4, :kc_5, :kc_6, :kc_7, :kc_8, :kc_9, :kc_0, :kc_equal, :kc_slash, :kc_delete, :kc_bspace],
      [toggle_layer(1), :kc_q, :kc_w, :kc_e, :kc_r, :kc_t, :kc_y, :kc_u, :kc_i, :kc_o, :kc_p, :kc_lbracket, :kc_rbracket, lock_layer(1)],
      [:kc_lctrl, :kc_a, :kc_s, :kc_d, :kc_f, :kc_g, :kc_h, :kc_j, :kc_k, :kc_l, :kc_scolon, :kc_quote, :kc_lgui, :kc_enter],
      # 1st position (kc_lshift) needs to be identical to the last one,
      # since the matrix has the same line and column pin on both positions
      [:kc_lshift, :kc_z, tap_or_toggle(:kc_x, :kc_lshift), :kc_c, :kc_v, :kc_b, :kc_n, :kc_m, :kc_comma, :kc_dot, :kc_grave, :kc_lshift],
      [:kc_lalt, :kc_space, :kc_ralt]
    ],
    [ # layer 1
      [:____, :____, :____, :____, :____, :____, :____, :____, :____, :____, :____, :____, :____, :____, :____],
      [:____, :kc_1, :kc_2, :kc_3, :kc_4, :kc_5, :kc_6, :kc_7, :kc_8, :kc_9, :kc_0, :kc_tab, :kc_bslash, :____],
      [:____, m(0), m(1), m(2), m(3), m(4), record(0), replay(0), :____, :____, :____, :____, :____, :____],
      [:____, :____, :____, m(5), :____, :____, :____, :____, :____, :____, :____, :____],
      [:____, :kc_x, :____]
    ]
  ]
end
