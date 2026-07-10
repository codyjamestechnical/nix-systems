{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "headscale";
    network_name = "headscale-internal";
    base_dir = "/docker-data/headscale";
    secrets_dir = "/etc/nixos/secrets";
    caddyfile = pkgs.writeText "Caddyfile" ''
      (ssl) {
        tls /ssl/fullchain.pem /ssl/privkey.pem
      }

      headplane.31337.im {
        import ssl
        redir / /admin
        reverse_proxy /admin* headscale-headplane:3000
      }

      http://headplane.31337.im:9250 {
        reverse_proxy headscale-tailscale-exporter:9250
      }
    '';
  };
in
{
  imports = [
    (import ./caddy.nix { inherit cfg; })
    (import ./tailscale.nix { inherit cfg; })
    (import ./docker-network.nix { inherit cfg; })
  ];

  ### ZSH SHELL ALIAS ###
  programs.zsh.shellAliases = {
      # headscale command alias so we don't have to use docker exec every time
      headscale = "docker exec -it headscale-server headscale";
  };

  ### FIREWALL ###
  networking.firewall = {
    # open ports for headscale and caddy
    allowedTCPPorts = [ 80 443 3478 ];
    allowedUDPPorts = [ 80 443 3478 ];
  };

  ### OCI CONTAINERS ###
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### HEADSCALE SERVER ###
    "${cfg.service_name}-server" = {
      image = "ghcr.io/juanfont/headscale:v0.28.0";
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
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/configs/headscale:/etc/headscale:rw"
        "${cfg.base_dir}/data/headscale/lib:/var/lib/headscale:rw"
        "${cfg.base_dir}/data/headscale/run:/var/run/headscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=headscale.cjtech.io"
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
      image = "ghcr.io/tale/headplane:0.6.2";
      dependsOn = [
        "${cfg.service_name}-server"
      ];
      volumes = [
        "${cfg.base_dir}/data/headscale/lib:/var/lib/headscale:rw"
        "${cfg.base_dir}/configs/headscale:/etc/headscale:rw"
        "${cfg.base_dir}/configs/headplane:/etc/headplane:rw"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=headscale-headplane"
        "--network=${cfg.network_name}"
        "--dns=1.1.1.1"
      ];
      labels = {
        "komodo.skip" = "";
        "homepage.group" = "Infrastructure & Monitoring";
        "homepage.name" = "Headplane";
        "homepage.icon" = "https://headplane.net/logo.svg";
        "homepage.href" = "https://headplane.31337.im";
        "homepage.description" = "Headscale dashboard and management UI";
        "homepage.siteMonitor" = "https://headplane.31337.im";
      };
    };


  ### TAILSCALE EXPORTER FOR PROMETHEUS ###
    "${cfg.service_name}-tailscale-exporter" = {
      image = "adinhodovic/tailscale-exporter:latest";
      dependsOn = [
        "${cfg.service_name}-server"
      ];
      volumes = [

      ];
      environment = {
        HEADSCALE_ADDRESS = "headscale.cjtech.io:50443";
        HEADSCALE_INSECURE = "false";
        LISTEN_ADDRESS = "0.0.0.0:9250";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      log-driver = "journald";
      extraOptions = [
        # "--network=container:${cfg.service_name}-caddy"
        "--network-alias=headscale-tailscale-exporter"
        "--network=${cfg.network_name}"
      ];
    };
  };

}
