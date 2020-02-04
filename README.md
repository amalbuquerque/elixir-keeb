# ElixirKeeb

Elixir keyboard firmware.

## Build steps

This will upload the firmware via SSH:

1. `export MIX_ENV=dev`
2. `export MIX_TARGET=rpi0_hid`
3. `export NERVES_NETWORK_PSK=atenas++`
4. `export NERVES_NETWORK_SSID=ligustrum`
5. `mix firmware`
6. `./upload.sh 10.0.0.109 /home/andre/projs/personal/elixir_keeb/_build/rpi0_hid_dev/nerves/images/elixir_keeb.fw`

## Debugging

Connect via SSH with `ssh 10.0.0.109`.

If it borked the SSH connection, insert the micro SD card on the PC and burn the firmware to it:

1. `export MIX_ENV=dev`
2. `export MIX_TARGET=rpi0_hid`
3. `export NERVES_NETWORK_PSK=atenas++`
4. `export NERVES_NETWORK_SSID=ligustrum`
5. `mix firmware.burn`

## Targets

Nerves applications produce images for hardware targets based on the
`MIX_TARGET` environment variable. If `MIX_TARGET` is unset, `mix` builds an
image that runs on the host (e.g., your laptop). This is useful for executing
logic tests, running utilities, and debugging. Other targets are represented by
a short name like `rpi3` that maps to a Nerves system image for that platform.
All of this logic is in the generated `mix.exs` and may be customized. For more
information about targets see:

https://hexdocs.pm/nerves/targets.html#content

## Getting Started

To start your Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: https://nerves-project.org/
  * Forum: https://elixirforum.com/c/nerves-forum
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves
