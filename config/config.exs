# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :elixir_keeb, target: Mix.target()

config :elixir_keeb, :modules,
  gadget: ElixirKeeb.Usb.Gadget,
  report: ElixirKeeb.Usb.Report,
  macros: ElixirKeeb.Macros,
  recordings: ElixirKeeb.Macros.Recordings,
  tap_or_toggle: ElixirKeeb.Advanced.TapOrToggle,
  web_dashboard: ElixirKeeb.Communication.WebDashboard

config :elixir_keeb,
  listener_wait_ms: 0,
  line_pins: [
    # {human-readable name, pin}
    {:AB, 14},
    {:AA, 15},
    {:A9, 18},
    {:A8, 23},
    {:A7, 24},
    {:A6, 25},
    {:A5, 1}, # moved to GPIO 1 from 8
    {:A4, 21}, # moved to GPIO 21 from 7
    {:A3, 12},
    {:A2, 16},
    {:A1, 20}
  ],
  column_pins: [
    # {human-readable name, pin}
    {:BA, 4},
    {:B9, 17},
    {:B8, 27},
    {:B7, 22},
    {:B6, 10},
    {:B5, 9},
    {:B4, 11},
    {:B3, 5},
    {:B2, 6},
    {:B1, 13}
  ],
  reporter: ElixirKeeb.Usb.Reporter,
  layout: ElixirKeeb.CanonTypewriter.Layout

config :elixir_keeb, :communication,
  module: ElixirKeeb.UIWeb.Keyboard,
  key_press_function: :broadcast_keydown,
  key_release_function: :broadcast_keyup

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_pack],
  app: Mix.Project.config()[:app]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [
  RingLogger,
  {ElixirKeeb.Communication.PhoenixChannelLoggerBackend, :keyboard}
]

config :logger,
  compile_time_purge_matching: [
      [level_lower_than: :info]
  ],
  level: :info

config :logger, :keyboard,
  module: ElixirKeeb.UIWeb.Keyboard,
  function: :broadcast_log_message

config :elixir_keeb_ui,
  namespace: ElixirKeeb.UI,
  representation: {ElixirKeeb.Representation, :to_dashboard},
  keyboard_layout: ElixirKeeb.CanonTypewriter.Layout

config :elixir_keeb_ui, ElixirKeeb.UIWeb.Endpoint,
  http: [port: 4000],
  server: true,
  # TODO: We aren't validating the requests, because if this was true we were
  # getting a 403 when trying to connect from to browser side via WebSockets.
  # This isn't recommended and needs to be revisited.
  check_origin: false,
  debug_errors: true,
  secret_key_base: "lyJTNxBjfH08ODTgiErmNZZw4jsR9Cv8lNMtvUrYtJULavMR3envdyBF6l2SsrYv",
  render_errors: [view: ElixirKeeb.UIWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: ElixirKeeb.UI.PubSub,
  live_view: [signing_salt: "gqyVWgdq"]

config :phoenix, :json_library, Jason

config :elixir_keeb, :latency_tracker,
  matrix_scan: [number_of_samples_kept: 30],
  matrix_to_usb: [number_of_samples_kept: 30]

config :elixir_keeb_ui, :barcharts,
  matrix_scan_latency: %{
    # number of columns
    categories: 30,
    series: 1,
    orientation: :vertical,
    show_selected: "no",
    title: "Matrix scan latency (ms)",
    type: :stacked,
    colour_scheme: "themed",

    # custom options
    plot_dimensions: {500, 300},
    values_range: {0, 10.0},
    data_source: [
      # MFA called to get the data list
      mfa: {
      ElixirKeeb.LatencyTracker,
      :get,
      [:matrix_scan]
      },
      wait_before_new_data_ms: 500
    ]
  },
  matrix_to_usb_latency: %{
    # number of columns
    categories: 30,
    series: 1,
    orientation: :vertical,
    show_selected: "no",
    title: "Matrix to USB latency (ms)",
    type: :stacked,
    colour_scheme: "default",

    # custom options
    plot_dimensions: {500, 300},
    values_range: {0, 40.0},
    data_source: [
      # MFA called to get the data list
      mfa: {
      ElixirKeeb.LatencyTracker,
      :get,
      [:matrix_to_usb]
      },
      wait_before_new_data_ms: 500
    ]
  }

if Mix.target() != :host do
  import_config "target.exs"
end

if Mix.env() == :test do
  import_config "#{Mix.env()}.exs"
end
