defmodule ElixirKeeb.Usb.Keycodes do
  alias ElixirKeeb.Utils
  use Bitwise

  @transparent_keycodes [:_, :__, :___, :____, :_____]

  # Keyboard/Keypad Page (0x07)
  # adapted from TMK/QMK qmk_firmware/tmk_core/common/keycode.h
  @normal_keycodes [
    :kc_no,                  # 0x00
    :kc_roll_over,
    :kc_post_fail,
    :kc_undefined,
    :kc_a,
    :kc_b,
    :kc_c,
    :kc_d,
    :kc_e,
    :kc_f,
    :kc_g,
    :kc_h,
    :kc_i,
    :kc_j,
    :kc_k,
    :kc_l,
    :kc_m,                   # 0x10
    :kc_n,
    :kc_o,
    :kc_p,
    :kc_q,
    :kc_r,
    :kc_s,
    :kc_t,
    :kc_u,
    :kc_v,
    :kc_w,
    :kc_x,
    :kc_y,
    :kc_z,
    :kc_1,
    :kc_2,
    :kc_3,                   # 0x20
    :kc_4,
    :kc_5,
    :kc_6,
    :kc_7,
    :kc_8,
    :kc_9,
    :kc_0,
    :kc_enter,
    :kc_escape,
    :kc_bspace,
    :kc_tab,
    :kc_space,
    :kc_minus,
    :kc_equal,
    :kc_lbracket,
    :kc_rbracket,            # 0x30
    :kc_bslash,
    :kc_nonus_hash,
    :kc_scolon,
    :kc_quote,
    :kc_grave,
    :kc_comma,
    :kc_dot,
    :kc_slash,
    :kc_capslock,
    :kc_f1,
    :kc_f2,
    :kc_f3,
    :kc_f4,
    :kc_f5,
    :kc_f6,
    :kc_f7,                  # 0x40
    :kc_f8,
    :kc_f9,
    :kc_f10,
    :kc_f11,
    :kc_f12,
    :kc_pscreen,
    :kc_scrolllock,
    :kc_pause,
    :kc_insert,
    :kc_home,
    :kc_pgup,
    :kc_delete,
    :kc_end,
    :kc_pgdown,
    :kc_right,
    :kc_left,                # 0x50
    :kc_down,
    :kc_up,
    :kc_numlock,
    :kc_kp_slash,
    :kc_kp_asterisk,
    :kc_kp_minus,
    :kc_kp_plus,
    :kc_kp_enter,
    :kc_kp_1,
    :kc_kp_2,
    :kc_kp_3,
    :kc_kp_4,
    :kc_kp_5,
    :kc_kp_6,
    :kc_kp_7,
    :kc_kp_8,                # 0x60
    :kc_kp_9,
    :kc_kp_0,
    :kc_kp_dot,
    :kc_nonus_bslash,
    :kc_application,
    :kc_power,
    :kc_kp_equal,
    :kc_f13,
    :kc_f14,
    :kc_f15,
    :kc_f16,
    :kc_f17,
    :kc_f18,
    :kc_f19,
    :kc_f20,
    :kc_f21,                 # 0x70
    :kc_f22,
    :kc_f23,
    :kc_f24,
    :kc_execute,
    :kc_help,
    :kc_menu,
    :kc_select,
    :kc_stop,
    :kc_again,
    :kc_undo,
    :kc_cut,
    :kc_copy,
    :kc_paste,
    :kc_find,
    :kc__mute,
    :kc__volup,              # 0x80
    :kc__voldown,
    :kc_locking_caps,
    :kc_locking_num,
    :kc_locking_scroll,
    :kc_kp_comma,
    :kc_kp_equal_as400,
    :kc_int1,
    :kc_int2,
    :kc_int3,
    :kc_int4,
    :kc_int5,
    :kc_int6,
    :kc_int7,
    :kc_int8,
    :kc_int9,
    :kc_lang1,               # 0x90
    :kc_lang2,
    :kc_lang3,
    :kc_lang4,
    :kc_lang5,
    :kc_lang6,
    :kc_lang7,
    :kc_lang8,
    :kc_lang9,
    :kc_alt_erase,
    :kc_sysreq,
    :kc_cancel,
    :kc_clear,
    :kc_prior,
    :kc_return,
    :kc_separator,
    :kc_out,                 # 0xa0
    :kc_oper,
    :kc_clear_again,
    :kc_crsel,
    :kc_exsel
    ]

    @normal @normal_keycodes |> Utils.zip_with_index(0x00)
                             |> Enum.into(%{})

    # modifiers exist on the first report byte
    # LCTRL on the 1st bit, RGUI on the last bit
    @modifier_keycodes [
      :kc_lctrl,
      :kc_lshift,
      :kc_lalt,
      :kc_lgui,
      :kc_rctrl,
      :kc_rshift,
      :kc_ralt,
      :kc_rgui
    ]

    @modifiers Utils.zip_with_index(@modifier_keycodes, 0)
    |> Enum.map(fn {keycode, position} -> {keycode, 1 <<< position} end)
    |> Enum.into(%{})

    @keycodes Map.merge(@normal, @modifiers)

    defguard normal?(keycode) when keycode in @normal_keycodes

    defguard modifier?(keycode) when keycode in @modifier_keycodes

    defguard transparent?(keycode) when keycode in @transparent_keycodes

    def is_normal?(keycode) when normal?(keycode), do: true

    def is_normal?(_keycode), do: false

    def is_modifier?(keycode) when modifier?(keycode), do: true

    def is_modifier?(_keycode), do: false

    def is_transparent?(keycode) when transparent?(keycode), do: true

    def is_transparent?(_keycode), do: false

    def value(keycode, state \\ :pressed)

    @doc """
    When keycode is a modifier, we don't care about the state
    because it will be "toggled" using a XOR with the modifier byte.

    E.g. modifier_byte = 0000 0000 ; lctrl = 0000 0001
      - toggle once: new modifier_byte = 0000 0001
      - toggle twice: new modifier_byte = 0000 0000
    """
    def value(keycode, _state) when modifier?(keycode) do
      Map.get(@keycodes, keycode)
    end

    def value(keycode, :pressed), do: Map.get(@keycodes, keycode)

    def value(_keycode, :released), do: 0x00
end
