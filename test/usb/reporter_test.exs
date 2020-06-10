defmodule ElixirKeeb.Usb.ReporterTest do
  use ExUnit.Case
  alias ElixirKeeb.KeycodeBehavior
  import Mox

  @subject ElixirKeeb.Usb.Reporter
  @device "/dev/dummy"
  @empty_input_report <<0, 0, 0, 0, 0, 0, 0, 0>>
  @key_pressed [{:kc_00, :pressed}]
  @key_released [{:kc_00, :released}]
  @slot 1
  @toggle_key %KeycodeBehavior{
    action: :toggle, layer: 1
  }
  @lock_key %KeycodeBehavior{
    action: :lock, layer: 1
  }
  @macro_key %KeycodeBehavior{
    action: :macro,
    identifier: 1,
    function: &__MODULE__.fake_macro_function/1
  }
  @record_key %KeycodeBehavior{
    action: :record,
    identifier: @slot
  }
  @macro_keys [:kc_a, :kc_n, :kc_d, :kc_r, :kc_e]

  @gadget Application.get_env(:elixir_keeb, :modules)[:gadget]
  @report Application.get_env(:elixir_keeb, :modules)[:report]
  @macros Application.get_env(:elixir_keeb, :modules)[:macros]
  @recordings Application.get_env(:elixir_keeb, :modules)[:recordings]
  @web_dashboard Application.get_env(:elixir_keeb, :modules)[:web_dashboard]
  @layout Application.get_env(:elixir_keeb, :layout)

  setup [:set_mox_global, :reporter]

  describe "Reporter GenServer" do
    test "it starts with the expected state", %{reporter: reporter} do
      assert %{
        activity: :regular,
        device: device_pid,
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        layout: @layout
      } = GenServer.call(reporter, :state)

      assert is_pid(device_pid)
    end

    test "it updates the state as expected, for a regular keypress", %{reporter: reporter} do
      updated_input_report = <<0, 1, 2, 3, 4, 5, 6, 7>>

      expect(@report, :update_report, fn _input_report, {:kc_a, :pressed} -> updated_input_report end)

      expect(@gadget, :raw_write, fn _device, ^updated_input_report -> :ok end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        activity: :regular,
        device: _device_pid,
        input_report: input_report,
        layer: 0,
        previous_layer: 0,
        layout: @layout
      } = GenServer.call(reporter, :state)

      assert updated_input_report == input_report
    end

    test "it doesn't write to the device, if the input report doesn't change", %{reporter: reporter} do

      expect(@report, :update_report, fn input_report, {:kc_a, :pressed} -> input_report end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        activity: :regular,
        device: _device_pid,
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        layout: @layout
      } = GenServer.call(reporter, :state)
    end

    test "when a `toggle` key is pressed, it doesn't write to the device and updates the state", %{reporter: reporter} do
      expect(@layout, :keycode, fn _kc_xy, _layer -> @toggle_key end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        activity: :regular,
        device: _device_pid,
        input_report: @empty_input_report,
        layer: 1,
        previous_layer: 0,
        layout: @layout
      } = GenServer.call(reporter, :state)
    end

    test "when a `toggle` key is released, it doesn't write to the device and updates the state", %{reporter: reporter} do
      expect(@layout, :keycode, 2, fn _kc_xy, _layer -> @toggle_key end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        layer: 1,
        previous_layer: 0,
        input_report: @empty_input_report
      } = GenServer.call(reporter, :state)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)
      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_released})

      assert %{
        layer: 0,
        previous_layer: 1,
        input_report: @empty_input_report
      } = GenServer.call(reporter, :state)
    end

    test "when a `lock` key is pressed, nothing happens", %{reporter: reporter} do
      expect(@layout, :keycode, fn _kc_xy, _layer -> @lock_key end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0
      } = GenServer.call(reporter, :state)
    end

    test "when a `lock` key is released, it doesn't write to the device and updates the state", %{reporter: reporter} do
      expect(@layout, :keycode, 2, fn _kc_xy, _layer -> @lock_key end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        layer: 0,
        previous_layer: 0,
        input_report: @empty_input_report
      } = GenServer.call(reporter, :state)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)
      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_released})

      assert %{
        layer: 1,
        previous_layer: 0,
        input_report: @empty_input_report
      } = GenServer.call(reporter, :state)
    end

    test "when a `macro` key is pressed, nothing happens", %{reporter: reporter} do
      expect(@layout, :keycode, fn _kc_xy, _layer -> @macro_key end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0
      } = GenServer.call(reporter, :state)
    end

    test "when a `macro` key is released, the macro keys are sent and the state updated", %{reporter: reporter} do
      expect(@layout, :keycode, fn _kc_xy, _layer -> @macro_key end)

      expect(@macros, :send_macro_keys, fn device, @macro_keys when is_pid(device) ->
        @empty_input_report # it doesn't matter
      end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_released})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        updated_by: :fake_macro_function
      } = GenServer.call(reporter, :state)
    end

    test "when a `record` key is pressed, nothing happens", %{reporter: reporter} do
      expect(@layout, :keycode, fn _kc_xy, _layer -> @record_key end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_pressed})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        activity: :regular
      } = GenServer.call(reporter, :state)
    end

    test "when a `record` key is released, the state activity changes to `:recording`", %{reporter: reporter} do
      expect(@layout, :keycode, fn _kc_xy, _layer -> @record_key end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_released})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        activity: {:recording, @slot}
      } = GenServer.call(reporter, :state)
    end

    test "when a `record` key is released, the state activity changes to `:regular` if it was `:recording`", %{reporter: reporter} do
      expect(@layout, :keycode, 2, fn _kc_xy, _layer -> @record_key end)

      expect(@report, :update_report, 0, fn _input_report, _keycode_and_action -> raise("Can't touch this!") end)

      expect(@gadget, :raw_write, 0, fn _device, _input_report -> raise("Can't touch this!") end)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_released})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        activity: {:recording, @slot}
      } = GenServer.call(reporter, :state)

      :ok = GenServer.cast(reporter, {:keys_pressed, @key_released})

      assert %{
        input_report: @empty_input_report,
        layer: 0,
        previous_layer: 0,
        activity: :regular
      } = GenServer.call(reporter, :state)
    end
  end

  defp reporter(context) do
    stub(@gadget, :open_device, fn _device ->
      {:ok, self()}
    end)

    stub(@report, :empty_report, fn -> @empty_input_report end)

    stub(@layout, :keycode, fn _kc_xy, _layer -> :kc_a end)

    stub(@web_dashboard, :communicate, fn _keycode_and_action -> :ok end)

    stub(@report, :update_report, fn input_report, _keycode_and_action -> input_report end)

    stub(@recordings, :maybe_record, fn state, _keycode_and_action -> state end)

    stub(@gadget, :raw_write, fn _device, _input_report -> :ok end)

    {:ok, reporter} = @subject.start_link(@device)

    Map.put(context, :reporter, reporter)
  end

  def fake_macro_function(state) do
    new_state = Map.put(state, :updated_by, :fake_macro_function)

    {@macro_keys, new_state}
  end
end
