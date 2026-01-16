{
  tailscale-config,
  config,
  pkgs,
  ...
}:
let
  defaultConfig = {
    hostname = config.networking.hostName;
    accept-dns = "true";
    login-server = "headscale.31337.im";
    advertise-exit-node = "false";
    advertise-tags = "tag:servers";
    accept-routes = "true";
  };
  cfg = tailscale-config // defaultConfig;
in
{
  services.tailscale = {
    enable = true;
    authKeyFile = "/secrets/tailscale_key";
    useRoutingFeatures = "both";
    extraUpFlags = [
      "--hostname=${cfg.hostname}"
      "--accept-dns=${cfg.accept-dns}"
      "--ssh"
      "--login-server=${cfg.login-server}"
      "--advertise-exit-node=${cfg.advertise-exit-node}"
      "--advertise-tags=${cfg.advertise-tags}"
      "--accept-routes=${cfg.accept-routes}"
    ];

  };

}
