{tailscale-config, config, pkgs, ... }:
let
  defaultConfig = {
    hostname = config.networking.hostName or "unnamed-device";
    accept-dns = true;
    login-server = "headscale.31337.im";
    advertise-exit-node = false;
    advertise-tags = "tag:servers";
    accept-routes = true;
    advertise-exit-node = false;
  };
  cfg = tailscail-config // defaultConfig;
in
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale_key";
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--hostname=${tailscale-config.hostname}"
      "--accept-dns=${tailscail-config.accept-dns}"
      "--ssh"
      "--login-server=${tailscail-config.login-server}"
      "--advertise-exit-node=${tailscail-config.advertise-exit-node}"
      "--advertise-tags=${tailscail-config.advertise-tags}"
      "--accept-routes=${tailscale-config.accept-routes}"
      "--advertise-exit-node=${tailscale-config.advertise-exit-node}"
    ];

  };

}