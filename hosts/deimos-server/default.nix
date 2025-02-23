{ inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix

        ../../modules/core.nix
        ../../modules/acme.nix
        ../../modules/docker.nix
        ../../users/docker.nix
        ../../users/cody.nix
    ];

    networking.hostName = "deimos-server";

    fileSystems."/docker-data" = {
        device = "//u429456.your-storagebox.de/backup";
        fsType = "cifs";
        options = let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";

        in ["${automount_opts},credentials=/var/secrets/smb-secrets"];
    };

    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            komodo-peripherie = {
                image = "ghcr.io/mbecker20/periphery:latest";
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

            beszel-agent = {
                image = "henrygd/beszel-agent";
                serviceName = "beszel-agent";
                extraOptions = ["--network=host"];
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock:ro"
                    "/docker-data/.beszel:/extra-filesystems/Docker_Data:ro"
                ];
                environment = {
                    PORT = "45876";
                    KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+L7U8f/hxIu5fj0fTVT2ngKHo4Kv+SaSdEbat25cA";
                };
                labels = {"komodo.skip" = "";};
            };
        };
        
    };

    system.stateVersion = "24.11";
}