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
            daemon.settings = {
                "hosts" = [
                    "unix:///var/run/docker.sock"
                    "tcp://0.0.0.0:2375"
                ]
            };
            
        };
    };

    # # Docker Containers
    # virtualisation.oci-containers = {
    #     backend = "docker";
    #     containers = {
    #         komodo-peripherie = {
    #             image = "ghcr.io/mbecker20/periphery:latest";
    #             ports = ["0.0.0.0:8120:8120"];
    #             log-driver = "local";
    #             volumes = [
    #                 "/var/run/docker.sock:/var/run/docker.sock"
    #                 "/proc:/proc"
    #                 "/etc/komodo/ssl:/etc/komodo/ssl"
    #                 "/etc/komodo/repos:/etc/komodo/repos"
    #                 "/etc/komodo/stacks:/etc/komodo/stacks"
    #                 "/var/secrets/komodo-passkey:/var/secrets/passkey"
    #             ];
    #             environment = {
    #                 PERIPHERY_SSL_ENABLED = "true";
    #                 PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
    #                 PERIPHERY_PASSKEYS_FILE = "/var/secrets/passkey";
    #             };
    #             labels = {"komodo.skip" = "";};
    #         };

    #         beszel-agent = {
    #             image = "henrygd/beszel-agent";
    #             serviceName = "beszel-agent";
    #             extraOptions = ["--network=host"];
    #             volumes = [
    #                 "/var/run/docker.sock:/var/run/docker.sock:ro"
    #             ];
    #             environment = {
    #                 PORT = "45876";
    #                 KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+L7U8f/hxIu5fj0fTVT2ngKHo4Kv+SaSdEbat25cA";
    #             };
    #         };
    #     };
        
    # };
}
