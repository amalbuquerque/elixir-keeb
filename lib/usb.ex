defmodule ElixirKeeb.Usb do
  @key_a "\0\0\x04\0\0\0\0\0"
  @key_A "\x02\0\x04\0\0\0\0\0"

  alias ElixirKeeb.Usb.Gadget

  def press_a(device) do
    Gadget.raw_write_and_release(device, @key_a)
  end

  def press_A(device) do
    Gadget.raw_write_and_release(device, @key_A)
  end
end
