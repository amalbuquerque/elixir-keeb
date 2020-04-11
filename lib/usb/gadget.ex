defmodule ElixirKeeb.Usb.Gadget do
  require Logger

  @release_all_keys "\0\0\0\0\0\0\0\0"

  @devices_path "/dev"
  @device_name "mygadget"
  @product "amalbuquerque USB device"
  @manufacturer "amalbuquerque"
  @serial_number "fedcba9876543210"

  @report_descriptor "\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0"

  def configure_device do
    Logger.info("Configuring the USB HID Gadget...")

    :ok = USBGadget.create_device(@device_name, %{
      "idVendor" => "0x1d6b",
      "idProduct" => "0x0104",
      "bcdDevice" => "0x0100",
      "bcdUSB" => "0x200",
      "strings" => %{
        "0x409" => %{
          "serialnumber" => @serial_number,
          "manufacturer" => @manufacturer,
          "product" => @product
        }
      }
    })

    :ok = USBGadget.create_config(@device_name, "c.1", %{
      "strings" => %{
        "0x409" => %{
          "configuration" => "Config 1: HID device"
        }
      }
    })

    :ok = USBGadget.create_function(@device_name, "hid.usb0", %{
      "protocol" => "1",
      "subclass" => "1",
      "report_length" => "8",
      "report_desc" => @report_descriptor
    })

    :ok = USBGadget.link_functions(@device_name, "c.1", ["hid.usb0"])

    {:ok, existing_devices} = current_devices()

    :ok = USBGadget.enable_device(@device_name)

    {:ok, new_devices} = current_devices()
    [new_device] = new_devices -- existing_devices

    Logger.info("Just configured device '#{new_device}' as an USB HID gadget.")

    Path.join(@devices_path, new_device)
  end

  def raw_write_and_release(device, to_write, time_to_release \\ 10) do
    spawn(fn ->
      raw_write(device, to_write)
      Process.sleep(time_to_release)
      raw_write(device, nil)
    end)
  end

  def raw_write(device, nil) when is_binary(device) do
    result = File.write(device, @release_all_keys)

    Logger.debug("Gadget.raw_write to #{device} with 'all-zeros' resulted in #{inspect(result)}")

    result
  end

  def raw_write(device, nil) when is_pid(device) do
    result = IO.write(device, @release_all_keys)

    Logger.debug("Gadget.raw_write to #{inspect(device)} with 'all-zeros' resulted in #{inspect(result)}")

    result
  end

  def raw_write(device, to_write) when is_binary(device) do
    result = File.write(device, to_write)

    Logger.debug("Gadget.raw_write to #{device} with '#{inspect(to_write)}' resulted in #{inspect(result)}")

    result
  end

  def raw_write(device, to_write) when is_pid(device) do
    result = IO.write(device, to_write)

    Logger.debug("Gadget.raw_write to #{inspect(device)} with '#{inspect(to_write)}' resulted in #{inspect(result)}")

    result
  end

  defp current_devices, do: File.ls(@devices_path)
end
