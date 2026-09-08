{ config, lib, pkgs, ... }:
let
  cfg = config.services.beszel-agent;
  inherit (lib) mkOption mkEnableOption mkIf types;
in
{
  options.services.beszel-agent = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to run the Beszel agent as an OCI container.";
    };

    zfsEnabled = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to pass /dev/zfs device into the container for ZFS metrics.";
    };

    serviceName = mkOption {
      type = types.str;
      default = "beszel-agent";
      description = "Name of the OCI container.";
    };

    image = mkOption {
      type = types.str;
      default = "henrygd/beszel-agent:alpine";
      description = "Container image to run.";
    };

    baseDir = mkOption {
      type = types.str;
      default = "/docker-data/.beszel";
      description = "Host directory mounted read-only at /extra-filesystems/Docker_Data.";
    };

    secretsDir = mkOption {
      type = types.str;
      default = "/etc/nixos/secrets";
      description = "Directory containing beszel-agent.env.";
    };

    extraVolumes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tank/media:/extra-filesystems/Media:ro" ];
      description = "Additional volume mounts appended to the default ones.";
    };

    extraDevices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional device mappings appended to the default ones.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.${cfg.serviceName} = {
      image = cfg.image;

      extraOptions = [
        "--network=host"
        "--cap-add=SYS_ADMIN"
        "--cap-add=SYS_RAWIO"
      ];

      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro"
        "/var/run/systemd/private:/var/run/systemd/private:ro"
        "${cfg.baseDir}:/extra-filesystems/Docker_Data:ro"
      ] ++ cfg.extraVolumes;

      environmentFiles = [
        "${cfg.secretsDir}/beszel-agent.env"
      ];

      devices =
        lib.optionals cfg.zfsEnabled [ "/dev/zfs:/dev/zfs" ]
        ++ cfg.extraDevices;

      labels = {
        "komodo.skip" = "";
      };
    };
  };
}


### BESZEL AGENT ENV SECRETS TEMPLATE ###
# This file should be stored in ${cfg.secrets_dir}/beszel-agent.env
# LISTEN=45876
# KEY=
# TOKEN=
# HUB_URL=
