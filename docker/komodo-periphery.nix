{ config, pkgs, ... }:
let
  cfg = {
    service_name = "komodo-periphery";
    network_name = "komodo-periphery-internal";
    base_dir = "/docker-data/komodo-periphery";
    secrets_dir = "/etc/nixos/secrets";
  };
in
{
  # Containers
  virtualisation.oci-containers.containers = {

    ### KOMODO PERIPHERY ###
    "${cfg.service_name}" = {
      image = "ghcr.io/moghtech/komodo-periphery:latest";
      ports = [ "0.0.0.0:8120:8120" ];
      log-driver = "journald";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"

        # "/etc/komodo/ssl:/etc/komodo/ssl"
        # "/etc/komodo/repos:/etc/komodo/repos"
        # "/etc/komodo/stacks:/etc/komodo/stacks"
        "${secrets_dir}/komodo-passkey:/passkey:ro"
      ];
      environment = {
        PERIPHERY_SSL_ENABLED = "true";
        PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
        PERIPHERY_PASSKEYS_FILE = "/passkey";
      };
      labels = {
        "komodo.skip" = "";
      };
    };

  };
}
