import Config

config :elixir_keeb, :modules,
  gadget: ElixirKeeb.Usb.GadgetMock,
  report: ElixirKeeb.Usb.ReportMock,
  macros: ElixirKeeb.MacrosMock,
  recordings: ElixirKeeb.Macros.RecordingsMock,
  web_dashboard: ElixirKeeb.Communication.WebDashboardMock

config :elixir_keeb,
  layout: ElixirKeeb.LayoutMock
