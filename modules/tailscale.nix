{ config, lib, ... }:
let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the tailscale module.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Hostname to advertise to Tailscale/Headscale.";
    };

    acceptDns = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Accept DNS configuration from Tailscale.";
    };

    loginServer = lib.mkOption {
      type = lib.types.str;
      default = "https://headscale.cjtech.io";
      description = "Tailscale/Headscale login server URL.";
    };

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Advertise this node as a Tailscale exit node.";
    };

    advertiseTags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "ACL tags to advertise (e.g. [ \"tag:server\" ]).";
    };

    acceptRoutes = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Accept subnet routes advertised by other nodes.";
    };
  };

  config = lib.mkIf cfg.enable {
    ### IPv4/IPv6 FORWARDING ###
    # Required when acting as an exit node.
    boot.kernel.sysctl = lib.mkIf cfg.advertiseExitNode {
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
        "--accept-dns=${lib.boolToString cfg.acceptDns}"
        "--ssh"
        "--login-server=${cfg.loginServer}"
        "--advertise-exit-node=${lib.boolToString cfg.advertiseExitNode}"
        "--accept-routes=${lib.boolToString cfg.acceptRoutes}"
      ] ++ lib.optionals (cfg.advertiseTags != []) [
        "--advertise-tags=${lib.concatStringsSep "," cfg.advertiseTags}"
      ];
    };
  };
}
