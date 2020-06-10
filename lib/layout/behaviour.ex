defmodule ElixirKeeb.Layout.Behaviour do
  @type kc_xy :: atom()
  @type layer :: integer()
  @type mapped_keycode :: atom()
  @callback keycode(kc_xy, layer) :: mapped_keycode
end
