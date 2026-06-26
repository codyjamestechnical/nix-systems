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
  # Containers\
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
