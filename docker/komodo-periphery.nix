{ config, pkgs, ... }:
{
  # Docker Containers
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      komodo-periphery = {
        image = "ghcr.io/moghtech/komodo-periphery:latest";
        ports = [ "0.0.0.0:8120:8120" ];
        log-driver = "local";
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"

          "/etc/komodo/ssl:/etc/komodo/ssl"
          "/etc/komodo/repos:/etc/komodo/repos"
          "/etc/komodo/stacks:/etc/komodo/stacks"
          "/secrets/komodo-passkey:/secrets/passkey"
        ];
        environment = {
          PERIPHERY_SSL_ENABLED = "true";
          PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
          PERIPHERY_PASSKEYS_FILE = "/secrets/passkey";
        };
        labels = {
          "komodo.skip" = "";
        };
      };
    };
  };
}
