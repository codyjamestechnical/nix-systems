{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "headscale";
    network_name = "headscale-internal";
    base_dir = "/docker-data/headscale";
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
        "/docker-data/.env.base"
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

    ### TAILSCALE ###
    "${cfg.service_name}-tailscale" = {
      image = "tailscale/tailscale:latest";
      labels = {
        "komodo.skip" = "";
      };
      dependsOn = [
        "${cfg.service_name}-server"
        "${cfg.service_name}-caddy"
      ];
      environmentFiles = [
        "/docker-data/.env.base"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "${cfg.base_dir}/data/tailscale:/var/lib/tailscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=container:headscale-caddy"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
      environment = {
        TS_HOSTNAME = "${cfg.service_name}";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_ACCEPT_DNS = "true";
        TS_USERSPACE = "false";
        TS_EXTRA_ARGS = "--advertise-tags=${cfg.tailscale_tags} --login-server=https://headscale.cjtech.io";
      };
    };

    ### HEADSCALE SERVER ###
    "${cfg.service_name}-server" = {
      image = "ghcr.io/juanfont/headscale:v0.27.2-rc.1";
      labels = {
        "komodo.skip" = "";
        "me.tale.headplane.target" = "headscale";
      };
      ports = [
        "443:443"
        "80:80"
        "3478:3478/udp"
        "50443:50443"
        "50443:50443/udp"
      ];
      environmentFiles = [
        "/docker-data/.env.base"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/configs/headscale:/etc/headscale:rw"
        "${cfg.base_dir}/data/headscale/lib:/var/lib/headscale:rw"
        "${cfg.base_dir}/data/headscale/run:/var/run/headscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=headscale headscale.cjtech.io"
        "--network=${cfg.network_name}"
        "--health-cmd='CMD headscale health'"
        "--dns=1.1.1.1"
      ];
      cmd = [
        "serve"
        "--config"
        "/etc/headscale/config.yaml"
      ];
    };

    ### HEADPLANE ###
    "${cfg.service_name}-headplane" = {
      image = "ghcr.io/tale/headplane:0.6.2-beta.3";
      dependsOn = [
        "/docker-data/.env.base"
        "${cfg.service_name}-server"
      ];
      volumes = [
        "${cfg.base_dir}/data/headscale/lib:/var/lib/headscale:rw"
        "${cfg.base_dir}/configs/headscale:/etc/headscale:rw"
        "${cfg.base_dir}/configs/headplane:/etc/headplane:rw"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      environmentFiles = [
        "${cfg.base_dir}/.env"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=headscale"
        "--network=${cfg.network_name}"
        "--dns=1.1.1.1"
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
