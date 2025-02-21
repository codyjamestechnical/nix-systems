{ config, pkgs, ...}:
{
    ## Virtualization Options
    virtualisation = {   
        docker = {
            enable = true;
            enableNvidia = false;
            autoPrune ={
                flags = [ "--all" ];
                enable = true;
                dates = "weekly";
            };
        };
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
                    "/var/komodo/ssl:/etc/komodo/ssl"
                    "/var/komodo/repos:/etc/komodo/repos"
                    "/var/komodo/stacks:/etc/komodo/stacks"
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
