{ config, pkgs, ...}:
{
    ## Virtualization Options
    virtualisation = {   
        docker = {
            enable = true;
            enableNvidia = true;
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
                ports = ["127.0.0.1:8120:8120"];
                log-driver = "local";
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/proc:/proc"
                    "/var/komodo/ssl:/etc/komodo/ssl"
                    "/var/komodo/repos:/etc/komodo/repos"
                    "/var/komodo/stacks:/etc/komodo/stacks"
                ];
                environment = {
                    PERIPHERY_SSL_ENABLED = "true";
                    PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
                    PERIPHERY_PASSKEYS_FILE = "/var/komodo/passkey";
                };
                labels = {"komodo.skip" = "";};
            };
        };
        
    };
}
