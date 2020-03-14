defmodule ElixirKeeb.Macros do
  alias ElixirKeeb.KeycodeBehavior
  import ElixirKeeb.Usb.Keycodes,
    only: [is_normal?: 1, normal?: 1, is_modifier?: 1, modifier?: 1]

  defmacro m(macro) when is_integer(macro) do
    quote do
      %KeycodeBehavior{
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
