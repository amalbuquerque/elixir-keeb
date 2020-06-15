defmodule ElixirKeeb.Macros do
  alias ElixirKeeb.Structs.KeycodeBehavior
  alias ElixirKeeb.Usb.{Report, Gadget}
  import ElixirKeeb.Usb.Keycodes,
    only: [is_normal?: 1, normal?: 1, is_modifier?: 1, modifier?: 1]
  require Logger

  @type input_report :: bitstring()
  @type device :: pid()
  @type keys :: list()
  @callback send_macro_keys(device, keys) :: input_report

  @macro_sleep_between_key_behavior_ms 10

  def send_macro_keys(device, macro_keys) do
    # reset the input report
    Gadget.raw_write(device, nil)

    macro_keys
    |> Enum.map(&convert_to_keycode/1)
    |> List.flatten()
    |> Enum.reduce(Report.empty_report(), fn keycode_and_state, input_report ->
      updated_input_report = Report.update_report(input_report, keycode_and_state)

      Logger.debug("Handling the macro step: #{inspect(keycode_and_state)}")

      Gadget.raw_write(device, updated_input_report)
      Process.sleep(@macro_sleep_between_key_behavior_ms)

      updated_input_report
    end)
  end

  def macro_function(macro_id, macro_content) when is_binary(macro_content) do
    macro_content = String.graphemes(macro_content)
    macro_function(macro_id, macro_content)
  end

  def macro_function(macro_id, macro_content) when is_list(macro_content) do
    function_name = macro_function_name(macro_id)

    quote do
      def unquote(function_name)(state) do
        {unquote(macro_content), state}
      end
    end
  end

  def macro_function(macro_id, macro_content) when is_function(macro_content) do
    function_name = macro_function_name(macro_id)

    quote do
      def unquote(function_name)(state) do
        unquote(macro_content).(state)
      end
    end
  end

  def macro_function_name(macro_id) when is_integer(macro_id) do
    String.to_atom("macro_#{macro_id}")
  end

  defmacro m(macro) when is_integer(macro) do
    function_name = macro_function_name(macro)

    quote do
      %KeycodeBehavior{
        identifier: unquote(macro),
        action: :macro,
        function: &__MODULE__.unquote(function_name)/1
      }
    end
  end

  defmacro record(slot) when is_integer(slot) do
    quote do
      %KeycodeBehavior{
        action: :record,
        identifier: unquote(slot)
      }
    end
  end

  defmacro replay(slot) when is_integer(slot) do
    quote do
      %KeycodeBehavior{
        action: :replay,
        identifier: unquote(slot)
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
