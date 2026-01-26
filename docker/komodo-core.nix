{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "komodo";
    network_name = "komodo-internal";
    base_dir = "/docker-data/komodo";
    secrets_dir = "/etc/nixos/secrets";
    tailscale_tags = "tag:core-infra";
  };
in
{
  # Containers
  virtualisation.oci-containers.containers = {

    ### CADDY ###
    "${cfg.service_name}-caddy" = {
      image = "caddy:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "${cfg.base-dir}/.env"
      ];
      volumes = [
        "${cfg.base-dir}/caddy:/data:rw"
        "${cfg.base-dir}/caddy/config:/config:rw"
        "${cfg.base-dir}/caddyfile:/etc/caddy/Caddyfile:ro"
        "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/ssl/privkey.pem:ro"
      ];
      ports = [
        "80:80/tcp"
        "443:443/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=caddy"
        "--network=${cfg.network_name}"
      ];
    };

    ### TAILSCALE ###
    "${cfg.service_name}-tailscale" = {
      image = "tailscale/tailscale:latest";
      labels = {
        "komodo.skip" = "";
      };
      dependsOn = [
        "${cfg.service_name}-caddy"
      ];
      environmentFiles = [
        "${cfg.base-dir}/.env"
      ];
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "${cfg.base-dir}/tailscale:/var/lib/tailscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=container:${cfg.service_name}-caddy"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
      environment = {
        TS_AUTHKEY = (builtins.readFile "${cfg.secrets_dir}/tailscale_key");
        TS_HOSTNAME = "${cfg.service_name}";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_ACCEPT_DNS = "true";
        TS_USERSPACE = "false";
        TS_EXTRA_ARGS = "--advertise-tags=${cfg.tailscale_tags} --login-server=https://headscale.cjtech.io";
      };
    };

    ### KOMODO PERIPHERY ###
    "${cfg.service_name}-periphery" = {
      image = "ghcr.io/moghtech/komodo-periphery:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "${cfg.base-dir}/.env"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        # "/etc/komodo/ssl:/etc/komodo/ssl"
        # "/etc/komodo/repos:/etc/komodo/repos"
        # "/etc/komodo/stacks:/etc/komodo/stacks"
        "${cfg.secrets-dir}/komodo-passkey:/etc/nixos/secrets/passkey:ro"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=periphery"
        "--network=${cfg.network_name}"
      ];
    };

    ### KOMODO CORE ###
    "${cfg.service_name}-core" = {
      image = "ghcr.io/moghtech/komodo-core:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "${cfg.base-dir}/.env"
      ];
      dependsOn = [
        "${cfg.service_name}-mongo"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=komodo-core"
        "--network=${cfg.network_name}"
      ];
    };

    ### MONGODB ###
    "${cfg.service_name}-mongo" = {
      image = "mongo";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "${cfg.base-dir}/.env"
      ];
      volumes = [
        "${cfg.base-dir}/mongodb/config:/data/configdb:rw"
        "${cfg.base-dir}/mongodb/data:/data/db:rw"
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

  ### NETWORK ###
  systemd.services."docker-network-${cfg.network_name}" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f ${cfg.network_name}";
    };
    script = ''
      docker network inspect ${cfg.network_name} || docker network create ${cfg.network_name} --ipv6
    '';

    wantedBy = [ "multi-user.target" ];
  };

}
