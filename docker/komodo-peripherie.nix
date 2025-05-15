{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            komodo-peripherie = {
                image = "ghcr.io/moghtech/komodo-periphery:latest";
                ports = ["0.0.0.0:8120:8120"];
                log-driver = "local";
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/proc:/proc"
                    "/etc/komodo/ssl:/etc/komodo/ssl"
                    "/etc/komodo/repos:/etc/komodo/repos"
                    "/etc/komodo/stacks:/etc/komodo/stacks"
                    "/var/secrets/komodo-passkey:/var/secrets/passkey"
                ];
                environment = {
                    PERIPHERY_SSL_ENABLED = "true";
                    PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
                    PERIPHERY_PASSKEYS_FILE = "/var/secrets/passkey";
                };
                labels = {"komodo.skip" = "";};
            };
        };
    };
}