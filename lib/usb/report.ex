defmodule ElixirKeeb.Usb.Report do
  use Bitwise
  alias ElixirKeeb.Usb.Keycodes
  import ElixirKeeb.Usb.Keycodes, only: [modifier?: 1]

  @type input_report :: bitstring()
  @type keycode :: atom()
  @type action :: atom()
  @type keycode_and_action :: {keycode, action}
  @callback empty_report() :: input_report
  @callback update_report(input_report, keycode_and_action) :: input_report

  @released_report_value 0x00
  @ignored 0x00
  @empty_input_report <<0, 0, 0, 0, 0, 0, 0, 0>>

  def empty_report, do: @empty_input_report

  def update_report(
        <<_mod, _, _key_0, _rest_keycodes::binary>> = previous_report,
        {keycode, _state}
      )
      when modifier?(keycode) do
    apply_modifier(previous_report, keycode)
  end

  def update_report(
        <<mod, _, _key_0, rest_keycodes::binary>>,
        {keycode, :pressed}
      ) do
    report_value = Keycodes.value(keycode)

    <<mod, @ignored, report_value>> <> rest_keycodes
  end

  def update_report(
        <<mod, _, _key_0, rest_keycodes::binary>>,
        {_keycode, :released}
      ) do
    <<mod, @ignored, @released_report_value>> <> rest_keycodes
  end

  def apply_modifier(previous_report, keycode) when modifier?(keycode) do
    <<modifier_byte::size(8), rest::binary>> = previous_report

    <<modifier_byte ^^^ Keycodes.value(keycode)>> <> rest
  end
end
