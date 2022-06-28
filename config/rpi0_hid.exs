import Config

config :vintage_net,
  config: [
    {"wlan0",
      %{
        type: VintageNetWiFi,
        vintage_net_wifi: %{
          regulatory_domain: "EU",
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
