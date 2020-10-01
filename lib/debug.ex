defmodule ElixirKeeb.Debug do
  @reporter ElixirKeeb.Usb.Reporter

  def reporter_state do
    reporter = Process.whereis(@reporter)

    GenServer.call(reporter, :state)
  end
end
