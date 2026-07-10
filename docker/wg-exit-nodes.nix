{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.wg-exit-nodes;

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

    # Enable docker backend for OCI containers if at least one instance is enabled
    virtualisation.oci-containers.backend = "docker";

    # Generate container configurations dynamically
    virtualisation.oci-containers.containers = mapAttrs' (name: inst: nameValuePair inst.service_name {
      image = "ghcr.io/juhovh/tailguard:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${inst.base_dir}/.env"
      ];
      volumes = [
        "${inst.base_dir}/config:/etc/wireguard:rw"
        "${inst.base_dir}/state:/tailguard/state:rw"
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
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_USERSPACE = "false";
        TS_HOSTNAME = "${inst.tailscale_hostname}";
        TS_LOGIN_SERVER = "https://headscale.cjtech.io";
        # Note: If you want to use tailscale_tags, you can reference it here.
        # But I use headscale which only allows specifying tags when creating the auth key.
        # e.g.:
        # TS_EXTRA_ARGS = "--advertise-tags=${inst.tailscale_tags}";
      };
    }) enabledInstances;

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
