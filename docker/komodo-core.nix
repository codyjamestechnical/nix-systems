{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "komodo";
    network_name = "komodo-internal";
    base_dir = "/docker-data/komodo";
    secrets_dir = "/etc/nixos/secrets";

    ## override tailscale config to attach it to the komodo-core instead of caddy
    tailscale_depends_on = [
      "${cfg.service_name}-core"
    ];
    tailscale_network = "container:${cfg.service_name}-core";
    # this is to help this container get a direct connection from tailscale
    # clients since this is a very important container
    tailscale_extra_tailscaled_args = "--port=41642";
  };
in
{
  # Import tailscale and docker-network modules
  imports = [
    (import ./tailscale.nix { inherit cfg; })
    (import ./docker-network.nix { inherit cfg; })
  ];

  ### FIREWALL ###
  networking.firewall = {
    # open UDP port for tailscale since we changed the port
    # the default port is 41641, but we changed it to 41642 in tailscale_extra_tailscaled_args
    allowedUDPPorts = [ 41642 ];
  };

  # Containers
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### KOMODO PERIPHERY ###
    "${cfg.service_name}-periphery" = {
      image = "ghcr.io/moghtech/komodo-periphery:2";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${cfg.secrets_dir}/komodo-periphery/keys:/config/keys"
        # "/etc/komodo/ssl:/etc/komodo/ssl"
        # "/etc/komodo/repos:/etc/komodo/repos"
        # "/etc/komodo/stacks:/etc/komodo/stacks"
        "${cfg.secrets_dir}/komodo-passkey:/var/secrets/passkey:ro"

      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=periphery"
        "--network=${cfg.network_name}"
      ];
    };

    ### KOMODO CORE ###
    "${cfg.service_name}-core" = {
      image = "ghcr.io/moghtech/komodo-core:2";
      ports = [ "41642:41642" ];
      labels = {
        "komodo.skip" = "";
        "homepage.group" = "Infrastructure & Monitoring";
        "homepage.name" = "Komodo";
        "homepage.icon" = "sh-komodo.svg";
        "homepage.href" = "https://komodo.31337.im";
        "homepage.description" = "Docker management & monitoring";
        "homepage.siteMonitor" = "https://komodo.31337.im";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      dependsOn = [
        "${cfg.service_name}-mongo"
      ];
      volumes = [
        "${cfg.base_dir}/keys:/config/keys"
        "/var/lib/acme/31337.im/fullchain.pem:/config/ssl/cert.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/config/ssl/key.pem:ro"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=komodo-core"
        "--network=${cfg.network_name}"
        # "--network=name=ipvlan6,ip6=2a01:4ff:f0:f9f1:1::2"
      ];
    };

    ### MONGODB ###
    "${cfg.service_name}-mongo" = {
      image = "mongo";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/mongodb/config:/data/configdb:rw"
        "${cfg.base_dir}/mongodb/data:/data/db:rw"
      ];
      cmd = [
        "--quiet"
        "--wiredTigerCacheSizeGB"
        "0.25"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=mongo"
        "--network=${cfg.network_name}"
      ];
    };
  };

  # systemd.services.docker-ipvlan-net = {
  #     description = "Create IPv6-only Docker IPvlan network";
  #     after = [ "docker.service" ];
  #     requires = [ "docker.service" ];
  #     wantedBy = [ "multi-user.target" ];
  #     before = [ "docker-tailscale.service" ];
  #     serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
  #     path = [ pkgs.docker ];
  #     script = ''
  #       if ! docker network inspect ipvlan6 >/dev/null 2>&1; then
  #         docker network create \
  #           --driver ipvlan \
  #           --opt ipvlan_mode=l3 \
  #           --ipv6 \
  #           --subnet "2a01:4ff:f0:f9f1:1::/80" \
  #           --opt parent=eth0 \
  #           ipvlan6
  #       fi
  #     '';
  #   };

}
