# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :elixir_keeb, target: Mix.target()

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
    {:A5, 8},
    {:A4, 7},
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

# Customize non-Elixir parts of the firmware. See
# https://hexdocs.pm/nerves/advanced-configuration.html for details.

config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

# Use shoehorn to start the main application. See the shoehorn
# docs for separating out critical OTP applications such as those
# involved with firmware updates.

config :shoehorn,
  init: [:nerves_runtime, :nerves_init_gadget],
  app: Mix.Project.config()[:app]

# Use Ringlogger as the logger backend and remove :console.
# See https://hexdocs.pm/ring_logger/readme.html for more information on
# configuring ring_logger.

config :logger, backends: [RingLogger]

if Mix.target() != :host do
  import_config "target.exs"
end
