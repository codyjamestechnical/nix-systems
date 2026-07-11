# Requires arkeep-agent.env set in the secrets directory.
{ config, pkgs, ... }:
let
  cfg = {
    service_name = "arkeep-agent";
    secrets_dir = "/etc/nixos/secrets";
    volumes = [
      "/root/.arkeep:/var/lib/arkeep-agent"
      "/docker-data:/hostfs/docker-data:rw"
    ];
  };
in
{
  ### OCI CONTAINERS ###
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### ARKEEP AGENT ###
    "${cfg.service_name}" = {
      image = "ghcr.io/arkeep-io/arkeep-agent:latest";
      extraOptions = [
        "--network=host"
      ];
      volumes = cfg.volumes;
      environmentFiles = [
        "${cfg.secrets_dir}/arkeep-agent.env"
      ];
      labels = {
        "komodo.skip" = "";
      };
    };

  };
}

### ARKEEP-AGENT.ENV TEMPLATE ###
# ARKEEP_SERVER_ADDR=[arkeep url without scheme]:9090
# ARKEEP_AGENT_SECRET=[agent secret key]
# ARKEEP_SERVER_HTTP_ADDR=[arkeep url with scheme (http/https)]
# ARKEEP_STATE_DIR=/var/lib/arkeep-agent
# TZ=AMERICA/NEW_YORK
