defmodule ElixirKeeb.Communication.WebDashboard do
  alias ElixirKeeb.Representation
  require Logger

  @web_dashboard_module Application.get_env(:elixir_keeb, :communication)[:module]
  @key_press_function Application.get_env(:elixir_keeb, :communication)[:key_press_function]
  @key_release_function Application.get_env(:elixir_keeb, :communication)[:key_release_function]

  def communicate({keycode, action}) when action in [:pressed, :released] do
    case is_nil(@web_dashboard_module) or
           is_nil(@key_press_function) or
           is_nil(@key_release_function) do
      true ->
        :nop

      _ ->

        string_keycode = Representation.string_representation(keycode)

        Logger.debug("Communicating {#{string_keycode}, #{action}} to Web Dashboard... (original keycode: #{inspect(keycode)})")

        _communicate(
          {string_keycode, action},
          @web_dashboard_module,
          @key_press_function,
          @key_release_function
        )
    end
  end

  defp _communicate(
         {string_keycode, :pressed},
         module,
         key_press_function,
         _key_release_function
       ) do
    Kernel.apply(module, key_press_function, [string_keycode])
  end

  defp _communicate(
         {string_keycode, :released},
         module,
         _key_press_function,
         key_release_function
       ) do
    Kernel.apply(module, key_release_function, [string_keycode])
  end
end
