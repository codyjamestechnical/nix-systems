# This module provides a declarative way to configure Wireguard Exit Node instances for tailscale using OCI containers.
# by default it uses the /docker-data/[instance name]/config directory for the wg-quick configuration file (wg0.conf).
# all you need to do is define the instances using the example below and place the wg0.conf file in the config directory
# and add the TAILSCALE_AUTHKEY to the .env file in /docker-data/[instance name]/ directory. The TAILSCALE_AUTHKEY
# will be deleted after the container has started for the first time, this fixes an issue with Headscale and keeping it there.
#
# For the example below, the wg config file should be placed in /docker-data/wg-exit-node-proton-toronto/config/wg0.conf
# and the TAILSCALE_AUTHKEY should be placed in the /docker-data/wg-exit-node-proton-toronto/.env file.
#
# NOTE: gluetun requires the [Peer] Endpoint in wg0.conf to be an IP address, not a domain name.
#
# ### TAILSCALE EXIT NODES -> WG VPN ###
# services.wg-exit-nodes = {

#   # Proton VPN Toronto
#   wg-exit-node-proton-toronto = {
#     enable = true;
#     tailscale_hostname = "proton-toronto";
#   };
# };

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.wg-exit-nodes;

  # iptables rules gluetun applies after its own firewall rules so tailscale
  # traffic can enter/leave via tailscale0 and be forwarded out over tun0.
  gluetunPostRules = pkgs.writeText "gluetun-post-rules.txt" ''
    iptables -A OUTPUT -o tailscale0 -d 100.64.0.0/10 -j ACCEPT
    iptables -I FORWARD 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i tailscale0 -o tun0 -j ACCEPT
    iptables -A FORWARD -i tun0 -o tailscale0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
  '';

  # Define the schema/options for a single instance
  instanceOpts = { name, ... }: {
    options = {
      enable = mkEnableOption "Enable this Wireguard Exit Node instance";

      service_name = mkOption {
        type = types.str;
        default = name;
        description = "Name of the service container.";
      };

      network_name = mkOption {
        type = types.str;
        default = "${name}-internal";
        description = "Docker network name.";
      };

      base_dir = mkOption {
        type = types.str;
        default = "/docker-data/${name}";
        description = "Base directory for container data and where the tailscale/headscale key will be placed in the .env file.";
      };

      tailscale_hostname = mkOption {
        type = types.str;
        default = name;
        description = "Tailscale hostname to set.";
      };

      tailscale_tags = mkOption {
        type = types.str;
        default = "tag:core-infra";
        description = "Tailscale tags to apply if you aren't using headscale.";
      };
    };
  };
in
{
  # 1. Define the option that users will configure in their system configuration
  options.services.wg-exit-nodes = mkOption {
    type = types.attrsOf (types.submodule instanceOpts);
    default = {};
    description = "Declarative Wireguard Exit Node instances.";
  };

  # 2. Generate the system configuration dynamically based on enabled instances
  config = let
    # Filter out any instances where `enable` is not set to true
    enabledInstances = filterAttrs (name: inst: inst.enable) cfg;
  in mkIf (enabledInstances != {}) {

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers =
      # Gluetun: owns the network namespace and runs the custom WireGuard tunnel
      (mapAttrs' (name: inst: nameValuePair "${inst.service_name}-gluetun" {
        image = "qmcgaw/gluetun:latest";
        labels = {
          "komodo.skip" = "";
        };
        environmentFiles = [
          "/docker-data/.env"
        ];
        volumes = [
          "${inst.base_dir}/config/wg0.conf:/gluetun/wireguard/wg0.conf:ro"
          "${gluetunPostRules}:/iptables/post-rules.txt:ro"
        ];
        log-driver = "journald";
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--network-alias=${inst.service_name}"
          "--network=${inst.network_name}"
          "--sysctl=net.ipv4.ip_forward=1"
          "--sysctl=net.ipv6.conf.all.forwarding=1"
          "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
          "--device=/dev/net/tun"
        ];
        environment = {
          VPN_SERVICE_PROVIDER = "custom";
          VPN_TYPE = "wireguard";
          DOT = "on";
        };
      }) enabledInstances)

      // # Tailscale: joins gluetun's network namespace so all its traffic exits via the VPN
      (mapAttrs' (name: inst: nameValuePair inst.service_name {
        image = "tailscale/tailscale:latest";
        dependsOn = [ "${inst.service_name}-gluetun" ];
        labels = {
          "komodo.skip" = "";
        };
        environmentFiles = [
          "/docker-data/.env"
          "${inst.base_dir}/.env"
        ];
        volumes = [
          "${inst.base_dir}/state:/var/lib/tailscale:rw"
        ];
        log-driver = "journald";
        extraOptions = [
          "--cap-add=NET_ADMIN"
          "--network=container:${inst.service_name}-gluetun"
          "--device=/dev/net/tun"
        ];
        environment = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_USERSPACE = "false";
          TS_HOSTNAME = "${inst.tailscale_hostname}";
          TS_LOGIN_SERVER = "https://headscale.cjtech.io";
          # TS_ACCEPT_DNS = "true";
          TS_EXTRA_ARGS = "--accept-dns=true --advertise-exit-node";
        };
      }) enabledInstances);

    ### IPv4/IPv6 FORWARDING ###
    # Enable IPv4/IPv6 forwarding as exit nodes require it to work properly
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
    };

    systemd.services =
      # Generate the docker network services
      (mapAttrs' (name: inst: nameValuePair "docker-network-${inst.network_name}" {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${inst.network_name}";
        };
        script = ''
          docker network inspect ${inst.network_name} || docker network create ${inst.network_name} --ipv6
        '';
        wantedBy = [ "multi-user.target" ];
      }) enabledInstances)

      // # MERGE: Extend the container services to delete TS_AUTHKEY after 1 minute
      (mapAttrs' (name: inst: nameValuePair "docker-${inst.service_name}" {
        postStart = ''
          # Schedule a transient systemd timer to delete the key in 1 minute
          ${pkgs.systemd}/bin/systemd-run \
            --on-active=1m \
            --timer-property=AccuracySec=1s \
            ${pkgs.bash}/bin/bash -c "
              if [ -f '${inst.base_dir}/.env' ]; then
                ${pkgs.gnused}/bin/sed -i '/^TS_AUTHKEY=/d' '${inst.base_dir}/.env'
              fi
            "
        '';
      }) enabledInstances);


  };
}
