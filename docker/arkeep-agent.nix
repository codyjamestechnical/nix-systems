# Requires arkeep-agent.env in the secrets directory.
{ config, lib, ... }:
let
  cfg = config.services.arkeep-agent;

  baseVolumes = [
    "/root/.arkeep:/var/lib/arkeep-agent"
    "/docker-data:/hostfs/docker-data:rw"
  ];
in
{
  options.services.arkeep-agent = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run the Arkeep agent container.";
    };

    secretsDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/secrets";
      description = "Directory containing arkeep-agent.env";
    };

    extraVolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "/srv/data:/hostfs/srv-data:ro" ];
      description = ''
        Additional bind mounts for the container. These are appended to the
        always-present base mounts:
        ${lib.concatStringsSep "\n" (map (v: "  - ${v}") baseVolumes)}
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.arkeep-agent = {
      image = "ghcr.io/arkeep-io/arkeep-agent:latest";
      extraOptions = [ "--network=host" ];
      volumes = baseVolumes ++ cfg.extraVolumes;
      environmentFiles = [ "${cfg.secretsDir}/arkeep-agent.env" ];
      labels."komodo.skip" = "";
    };
  };
}


### ARKEEP-AGENT.ENV TEMPLATE ###
# ARKEEP_SERVER_ADDR=[arkeep url without scheme]:9090
# ARKEEP_AGENT_SECRET=[agent secret key]
# ARKEEP_SERVER_HTTP_ADDR=[arkeep url with scheme (http/https)]
# ARKEEP_STATE_DIR=/var/lib/arkeep-agent
# TZ=AMERICA/NEW_YORK
