{ config, pkgs, ... }:
let
  cfg = {
    service_name = "beszel-agent";
    network_name = "beszel-internal";
    base_dir = "/docker-data/.beszel";
    secrets_dir = "/etc/nixos/secrets";
  };
in
{
  # Containers
  virtualisation.oci-containers.containers = {

    ### BESZEL AGENT ###
    "${cfg.service_name}" = {
      image = "henrygd/beszel-agent";
      extraOptions = [
        "--network=host"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
        "${cfg.base_dir}:/extra-filesystems/Docker_Data:ro"
      ];
      environmentFiles = [
        "${cfg.secrets_dir}/beszel-agent.env"
      ];
      labels = {
        "komodo.skip" = "";
      };
    };

  };
}
