use Mix.Config

config :nerves_network,
  regulatory_domain: "EU"

config :nerves_network, :default,
  wlan0: [
    networks: [
      [
        ssid: System.get_env("NERVES_NETWORK_SSID"),
        psk: System.get_env("NERVES_NETWORK_PSK"),
        key_mgmt: :"WPA-PSK"
      ]
    ]
  ]
