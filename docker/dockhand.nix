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
        "${cfg.service_name}-server"
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
        "--network=container:${cfg.service_name}-server"
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

    ### DOCKHAND ###
    "${cfg.service_name}-server" = {
      image = "fnsys/dockhand:latest";
      user = "0:0";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${cfg.base_dir}/data:/app/data"
        "${cfg.acme_cert}:/etc/dockhand/certs/cert.pem:ro"
        "${cfg.acme_key}:/etc/dockhand/certs/key.pem:ro"
      ];
      environment = {
        HTTPS_MODE = "on";
        HTTPS_CERT_PATH = "/etc/dockhand/certs/cert.pem";
        HTTPS_KEY_PATH = "/etc/dockhand/certs/key.pem";
        PORT = "443";
        ORIGIN = "https://dockhand.31337.im";
      };
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
