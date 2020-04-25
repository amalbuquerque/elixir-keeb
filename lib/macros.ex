defmodule ElixirKeeb.Macros do
  alias ElixirKeeb.KeycodeBehavior
  alias ElixirKeeb.Usb.{Report, Gadget}
  import ElixirKeeb.Usb.Keycodes,
    only: [is_normal?: 1, normal?: 1, is_modifier?: 1, modifier?: 1]
  require Logger

  @macro_sleep_between_key_behavior_ms 10

  def send_macro_keys(device, macro_keys) do
    # reset the input report
    Gadget.raw_write(device, nil)

    macro_keys
    |> Enum.reduce(Report.empty_report(), fn keycode_and_state, input_report ->
      updated_input_report = Report.update_report(input_report, keycode_and_state)

      Logger.debug("Handling the macro step: #{inspect(keycode_and_state)}")

      Gadget.raw_write(device, updated_input_report)
      Process.sleep(@macro_sleep_between_key_behavior_ms)

      updated_input_report
    end)
  end

  defmacro m(macro) when is_integer(macro) do
    quote do
      %KeycodeBehavior{
        identifier: unquote(macro),
        action: :macro,
        keys: Enum.at(@macros, unquote(macro))
              |> Enum.map(&unquote(__MODULE__).convert_to_keycode/1)
              |> List.flatten()
      }
    end
  end

  def convert_to_keycode(keycode) when is_binary(keycode) do
    maybe_keycode = String.to_atom("kc_#{keycode}")

    case is_normal?(maybe_keycode) do
      true ->
        convert_to_keycode(maybe_keycode)
      _ ->
        raise("'#{keycode}' can't be translated to a proper keycode.")
    end
  end

  def convert_to_keycode(keycode) when normal?(keycode) do
    [:pressed, :released]
    |> Enum.map(&{keycode, &1})
  end

  def convert_to_keycode({modifier, state}) when is_binary(modifier) do
    maybe_modifier = String.to_atom("kc_#{modifier}")

    case is_modifier?(maybe_modifier) do
      true ->
        convert_to_keycode({maybe_modifier, state})
      _ ->
        raise("'#{modifier}' can't be translated to a proper keycode.")
    end
  end

  def convert_to_keycode({modifier, state}) when modifier?(modifier) do
    {modifier, state}
  end
end
