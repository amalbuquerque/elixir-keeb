# ElixirKeeb

Elixir keyboard firmware.

## Features

This firmware supports:

- Working like a standard keyboard, ie., a layout with a single layer;
- Multiple layers (toggled or locked by a key press);
- Fully programmable macros (run arbitrary code, besides sending keypresses);
- Record macros on the fly (e.g. `record to X` and `replay X` keys);
- Web dashboard (shows keys currently pressed + log messages).
    * Macros have an identifier, passed to the dashboard through the `Representation` module;

## TODO

- Move modules to `lib/elixir_keeb`, instead of having them on the `lib` folder;
- Special recording macro that stores the keypresses in a stack, useful to obtain input from the user;
- Metrics for GPIO read latency + GPIO to keypress latency;
- Redefine layout without having to burn firmware again;
- Bump Nerves versions;
- Use Gitlab Actions for CI;
- Tap to send a key press, keep pressed to activate a layer or send a modifier;

## Wishlist

- Activate LEDs;
- Handles host going to sleep and waking up;
- Debug mode;
- Chording (e.g. pressing simultaneously `u` and `i` sends a third key press, instead of `u` or `i`);

## Build steps

This will upload the firmware via SSH (check your keyboard IP on your router):

1. `export MIX_ENV=prod`
2. `export MIX_TARGET=rpi0_hid`
3. `export NERVES_NETWORK_PSK=<password>`
4. `export NERVES_NETWORK_SSID=<ssid>`
5. `mix firmware`
6. `./upload.sh <keeb IP> /home/andre/projs/personal/elixir_keeb/_build/rpi0_hid_prod/nerves/images/elixir_keeb.fw`

## Debugging

Connect via SSH with `ssh <keeb IP>`.

You can check the web dashboard on `<keeb IP>:4000`

If it borked the SSH connection, insert the micro SD card on the PC and burn the firmware to it:

1. `export MIX_ENV=dev`
2. `export MIX_TARGET=rpi0_hid`
3. `export NERVES_NETWORK_SSID=<ssid>`
4. `export NERVES_NETWORK_PSK=<password>`
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
