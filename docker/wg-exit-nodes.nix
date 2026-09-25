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

  ociBin = config.virtualisation.oci-containers.backend;
  isPodman = ociBin == "podman";

  # Rootless podman: containers run as this user, so networks must be created
  # in the same user's rootless podman instance (not via the root docker socket).
  rootlessUser = "podman";
  netBin =
    if isPodman
    then "${config.virtualisation.podman.package}/bin/podman"
    else "${pkgs.docker}/bin/docker";

  # iptables rules gluetun applies after its own firewall rules so tailscale
  # traffic can enter/leave via tailscale0 and be forwarded out over tun0.
  gluetunPostRules = pkgs.writeText "gluetun-post-rules.txt" ''
    iptables -A OUTPUT -o tailscale0 -d 100.64.0.0/10 -j ACCEPT
    iptables -I FORWARD 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -i tailscale0 -o tun0 -j ACCEPT
    iptables -A FORWARD -i tun0 -o tailscale0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    ip6tables -A OUTPUT -o tailscale0 -d fd7a:115c:a1e0::/48 -j ACCEPT
    ip6tables -I FORWARD 1 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    ip6tables -A FORWARD -i tailscale0 -o tun0 -j ACCEPT
    ip6tables -A FORWARD -i tun0 -o tailscale0 -j ACCEPT
    ip6tables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
    # Add MSS Clamping for nested VPNs
    iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    ip6tables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

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

    virtualisation.oci-containers.containers =
      # Gluetun: owns the network namespace and runs the custom WireGuard tunnel
      (mapAttrs' (name: inst: nameValuePair "${inst.service_name}-gluetun" {
        image = "qmcgaw/gluetun:latest";
        podman = mkIf isPodman { user = rootlessUser; };
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
          "--cap-add=NET_RAW"
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
        podman = mkIf isPodman { user = rootlessUser; };
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
          "--cap-add=NET_RAW"
          "--network=container:${inst.service_name}-gluetun"
          "--device=/dev/net/tun"
        ];
        # gluetun's low-priority ip rules (99/101) push replies to tailnet peers out tun0.
         # Send the tailnet ranges to Tailscale's table 52 ahead of gluetun's rules.
         entrypoint = "/bin/sh";
         cmd = [
           "-c"
           ''
             ip rule add to 100.64.0.0/10 table 52 priority 90 2>/dev/null || true
             ip -6 rule add to fd7a:115c:a1e0::/48 table 52 priority 90 2>/dev/null || true
             exec /usr/local/bin/containerboot
           ''
         ];
        environment = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_USERSPACE = "false";
          TS_HOSTNAME = "${inst.tailscale_hostname}";
          TS_ACCEPT_DNS = "true";
          TS_EXTRA_ARGS = "--advertise-exit-node --login-server=https://headscale.cjtech.io";
          # TS_DEBUG_FIREWALL_MODE = "nftables";
        };
      }) enabledInstances);

    ### IPv4/IPv6 FORWARDING ###
    # Enable IPv4/IPv6 forwarding as exit nodes require it to work properly
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;

      # Enable TCP BBR Congestion Control
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";

      # Increase UDP socket buffers (2.5MB) for WireGuard/Tailscale
      "net.core.rmem_max" = 2500000;
      "net.core.wmem_max" = 2500000;
    };

    systemd.services =
      # Generate the container network services. With rootless podman the
      # network must be created by the same user the containers run as.
      (mapAttrs' (name: inst: nameValuePair "${ociBin}-network-${inst.network_name}" {
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${netBin} network rm -f ${inst.network_name}";
        } // optionalAttrs isPodman {
          User = rootlessUser;
        };
        environment = optionalAttrs isPodman {
          HOME = config.users.users.${rootlessUser}.home;
        };
        script = ''
          ${netBin} network inspect ${inst.network_name} || ${netBin} network create ${inst.network_name} --ipv6
        '';
        wantedBy = [ "multi-user.target" ];
      }) enabledInstances)

      // # MERGE: Extend the container services to delete TS_AUTHKEY after 1 minute
      (mapAttrs' (name: inst: nameValuePair "${ociBin}-${inst.service_name}" {
        # Background the delayed cleanup so ExecStartPost returns immediately.
        # This runs as the container service's user, which owns the .env file.
        postStart = ''
          (
            ${pkgs.coreutils}/bin/sleep 60
            if [ -f '${inst.base_dir}/.env' ]; then
              ${pkgs.gnused}/bin/sed -i '/^TS_AUTHKEY=/d' '${inst.base_dir}/.env'
            fi
          ) &
        '';
      }) enabledInstances);



  };
}
