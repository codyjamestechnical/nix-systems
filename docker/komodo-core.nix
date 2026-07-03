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
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### CADDY ###
    # "${cfg.service_name}-caddy" = {
    #   image = "caddy:latest";
    #   labels = {
    #     "komodo.skip" = "";
    #   };
    #   environmentFiles = [
    #     "/docker-data/.env"
    #     "${cfg.base_dir}/.env"
    #   ];
    #   volumes = [
    #     "${cfg.base_dir}/caddy:/data:rw"
    #     "${cfg.base_dir}/caddy/config:/config:rw"
    #     "${cfg.base_dir}/caddyfile:/etc/caddy/Caddyfile:ro"
    #     "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
    #     "/var/lib/acme/31337.im/key.pem:/ssl/privkey.pem:ro"
    #   ];
    #   log-driver = "journald";
    #   extraOptions = [
    #     "--cap-add=NET_ADMIN"
    #     "--network-alias=caddy"
    #     "--network=${cfg.network_name}"

    #   ];
    # };

    ### TAILSCALE ###
    "${cfg.service_name}-tailscale" = {
      image = "tailscale/tailscale:latest";
      labels = {
        "komodo.skip" = "";
      };
      dependsOn = [
        "${cfg.service_name}-core"
      ];
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "${cfg.base_dir}/tailscale:/var/lib/tailscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=container:${cfg.service_name}-core"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
      environment = {
        TS_HOSTNAME = "${cfg.service_name}";
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_ACCEPT_DNS = "false";
        TS_USERSPACE = "false";
        TS_EXTRA_ARGS = "--advertise-tags=${cfg.tailscale_tags} --login-server=https://headscale.cjtech.io";
        TS_TAILSCALED_EXTRA_ARGS = "--port=41642";
      };
    };

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
        "--network=name=ipvlan6,ip6=2a01:4ff:f0:f9f1::2"
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
  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -s 172.17.0.0/16 -p udp --sport 41642 \
      -o eth0 -j SNAT --to-source 5.161.235.16:41642
  '';
  ### NETWORK ###
  systemd.services."docker-network-${cfg.network_name}" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f ${cfg.network_name}";
    };
    script = ''
      docker network inspect ${cfg.network_name} || docker network create ${cfg.network_name} --ipv6 --internal --driver bridge
    '';

    wantedBy = [ "multi-user.target" ];
  };

  systemd.services.docker-ipvlan-net = {
      description = "Create IPv6-only Docker IPvlan network";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      before = [ "docker-tailscale.service" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      path = [ pkgs.docker ];
      script = ''
        if ! docker network inspect ipvlan6 >/dev/null 2>&1; then
          docker network create \
            --driver ipvlan \
            --opt ipvlan_mode=l2 \
            --ipv6 \
            --subnet "2a01:4ff:f0:f9f1::/64" \
            --gateway "2a01:4ff:f0:f9f1::1" \
            --opt parent=eth0 \
            ipvlan6
        fi
      '';
    };

}
