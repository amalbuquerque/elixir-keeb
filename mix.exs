defmodule ElixirKeeb.MixProject do
  use Mix.Project

  @app :elixir_keeb
  @version "0.1.0"
  @all_targets [:rpi0, :rpi0_hid]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ElixirKeeb.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.5.0", runtime: false},
      {:shoehorn, "~> 0.6"},
      {:ring_logger, "~> 0.6"},
      {:toolshed, "~> 0.2"},
      {:httpoison, "~> 1.7.0"},
      {:jason, "~> 1.2.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.6", targets: @all_targets},
      {:nerves_init_gadget, "~> 0.4", targets: @all_targets},
      {:usb_gadget, git: "https://github.com/nerves-project/usb_gadget.git", branch: "master", targets: @all_targets},
      {:circuits_gpio, "~> 0.4.3", targets: @all_targets},

      # Dependencies for specific targets
      {:nerves_system_rpi0, "~> 1.8", runtime: false, targets: :rpi0},
      {:nerves_system_rpi0_hid, path: "../nerves_custom_rpi0", runtime: false, targets: :rpi0_hid, nerves: [compile: true]},
      {:mix_test_watch, "~> 1.0.2", only: :test},
      {:mox, "~> 0.5.2", only: :test},
      {:elixir_keeb_ui, path: "../elixir_keeb_ui", targets: @all_targets},
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "#{@app}_cookie",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
