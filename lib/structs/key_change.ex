defmodule ElixirKeeb.Structs.KeyChange do
  import ElixirKeeb.PhysicalKeycodes,
    only: [kc_xy?: 1]

  @states [:pressed, :released]

  @fields [
    :kc_xy,
    :keycode,
    :state,
    :read_at
  ]

  # this struct will be created by the listener,
  # who doesn't know how to translate kc_xy into keycodes
  @enforce_keys @fields -- [:keycode]
  defstruct @fields

  defguard key_state?(state) when state in @states

  def new(
        kc_xy,
        state
      )
  when kc_xy?(kc_xy) and key_state?(state) do
        %__MODULE__{
          kc_xy: kc_xy,
          state: state,
          read_at: System.monotonic_time(:microsecond)
        }
  end
end
