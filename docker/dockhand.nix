{ config, pkgs, ... }:
let
  cfg = {
    service_name = "dockhand";
    network_name = "dockhand-internal";
    base_dir = "/docker-data/dockhand";
    secrets_dir = "/etc/nixos/secrets";
    acme_cert = "/var/lib/acme/31337.im/fullchain.pem";
    acme_key = "/var/lib/acme/31337.im/fullchain.pem";
  };
in
{
  # Containers
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### TAILSCALE ###
    "${cfg.service_name}-tailscale" = {
      image = "tailscale/tailscale:latest";
      dependsOn = [
        "${cfg.service_name}-caddy"
      ];
      environmentFiles = [
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "${cfg.base_dir}/tailscale:/var/lib/tailscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=container:${cfg.service_name}-caddy"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
      environment = {
        TS_HOSTNAME = "${cfg.service_name}";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_ACCEPT_DNS = "false";
        TS_USERSPACE = "false";
        TS_EXTRA_ARGS = "--login-server=https://headscale.cjtech.io";
      };
    };

    ### CADDY ###
    "${cfg.service_name}-caddy" = {
      image = "caddy:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/caddy/data:/data:rw"
        "${cfg.base_dir}/caddy/config:/config:rw"
        "${cfg.base_dir}/configs/caddy/caddyfile.txt:/etc/caddy/Caddyfile:ro"
        "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/ssl/privkey.pem:ro"
      ];
      log-driver = "journald";
      ports = [

      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=caddy"
        "--network=${cfg.network_name}"
      ];
    };

    ### DOCKHAND ###
    "${cfg.service_name}-server" = {
      image = "fnsys/dockhand:latest";
      user = "0:0";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${cfg.base_dir}/data:/app/data"
      ];
      extraOptions = [
        "--network-alias=${cfg.service_name}-server"
        "--network=${cfg.network_name}"
      ];
    };

  };

  # One-shot service to remove TS_AUTHKEY from .env 1 minute after tailscale starts.
  # After the first successful auth the key is no longer needed (state is persisted).
  systemd.services."${cfg.service_name}-tailscale-authkey-cleanup" = {
    description = "Remove TS_AUTHKEY from ${cfg.service_name} .env after tailscale authenticates";
    after = [ "docker-${cfg.service_name}-tailscale.service" ];
    wantedBy = [ "docker-${cfg.service_name}-tailscale.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cleanup-ts-authkey" ''
        sleep 60
        ${pkgs.gnused}/bin/sed -i '/^TS_AUTHKEY/d' "${cfg.base_dir}/.env"
      '';
    };
  };


}
