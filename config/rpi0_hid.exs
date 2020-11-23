use Mix.Config

config :vintage_net,
  regulatory_domain: "EU",
  config: [
    {"wlan0",
      %{
        type: VintageNetWiFi,
        vintage_net_wifi: %{
          networks: [
            %{
              key_mgmt: :wpa_psk,
              ssid: System.get_env("NERVES_NETWORK_SSID"),
              psk: System.get_env("NERVES_NETWORK_PSK"),
            }
          ]
        },
        ipv4: %{method: :dhcp},
      }
    }
  ]
