defmodule ElixirKeeb.Macros do
  import ElixirKeeb.Usb.Keycodes, only: [normal?: 1, modifier?: 1]

  def convert_to_keycode(keycode) when normal?(keycode) do
    [:pressed, :released]
    |> Enum.map(&{keycode, &1})
  end

  def convert_to_keycode({modifier, state}) when modifier?(modifier) do
    {modifier, state}
  end
end
