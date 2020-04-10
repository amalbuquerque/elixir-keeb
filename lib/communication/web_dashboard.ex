defmodule ElixirKeeb.Communication.WebDashboard do
  alias ElixirKeeb.Representation

  @web_dashboard_module Application.get_env(:elixir_keeb, :module)
  @key_press_function Application.get_env(:elixir_keeb, :key_press_function)
  @key_release_function Application.get_env(:elixir_keeb, :key_release_function)

  def communicate({_keycode, _action} = keycode_and_action) do
    case is_nil(@web_dashboard_module) or
           is_nil(@key_press_function) or
           is_nil(@key_release_function) do
      true ->
        :nop

      _ ->
        _communicate(
          keycode_and_action,
          @web_dashboard_module,
          @key_press_function,
          @key_release_function
        )
    end
  end

  defp _communicate(
         {keycode, :pressed},
         module,
         key_press_function,
         _key_release_function
       ) do
    string_keycode = Representation.string_representation(keycode)

    Kernel.apply(module, key_press_function, [string_keycode])
  end

  defp _communicate(
         {keycode, :released},
         module,
         _key_press_function,
         key_release_function
       ) do
    string_keycode = Representation.string_representation(keycode)

    Kernel.apply(module, key_release_function, [string_keycode])
  end
end
