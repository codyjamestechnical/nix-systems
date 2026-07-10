{
  tailscale-config,
  config,
  pkgs,
  lib,
  ...
}:
let
  defaultConfig = {
    hostname = config.networking.hostName;
    accept-dns = "true";
    login-server = "https://headscale.cjtech.io";
    advertise-exit-node = "false";
    advertise-tags = "";
    accept-routes = "true";
  };
  cfg = defaultConfig // tailscale-config;
in
{
  ### IPv4/IPv6 FORWARDING ###
  # Enable IPv4/IPv6 forwarding if advertise-exit-node is enabled
  # as exit nodes require forwarding to work properly
  boot.kernel.sysctl = lib.mkIf (cfg.advertise-exit-node == "true") {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
  };

  ### TAILSCALE SERVICE CONFIG ###
  services.tailscale = {
    enable = true;
    authKeyFile = "/etc/nixos/secrets/tailscale_key";
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
