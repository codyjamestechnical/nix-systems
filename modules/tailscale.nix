{
  tailscale-config,
  config,
  pkgs,
  ...
}:
let
  defaultConfig = {
    hostname = "${config.networking.hostName}" or "unnamed-device";
    accept-dns = true;
    login-server = "headscale.31337.im";
    advertise-exit-node = false;
    advertise-tags = "tag:servers";
    accept-routes = true;
  };
  cfg = tailscale-config // defaultConfig;
in
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/var/secrets/tailscale_key";
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--hostname=${tailscale-config.hostname}"
      "--accept-dns=${tailscale-config.accept-dns}"
      "--ssh"
      "--login-server=${tailscale-config.login-server}"
      "--advertise-exit-node=${tailscale-config.advertise-exit-node}"
      "--advertise-tags=${tailscale-config.advertise-tags}"
      "--accept-routes=${tailscale-config.accept-routes}"
    ];

  };

}
