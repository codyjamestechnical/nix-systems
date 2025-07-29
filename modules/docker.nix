{ config, pkgs, ...}:
{
    ## Virtualization Options
    virtualisation = {   
        docker = {
            enable = true;
            # rootless = {
            #     enable = true;
            #     setSocketVariable = true;
            #     daemon.settings = {
            #         ipv6 = true;
            #         hosts = [
            #             "unix:///run/user/1000/docker.sock"
            #             "tcp://0.0.0.0:2375"
            #         ];
            #     };
            # };

            enableNvidia = false;
            autoPrune ={
                flags = [ "--all" ];
                enable = true;
                dates = "weekly";
            };
            daemon.settings = {
                userland-proxy = false;
                "hosts" = [
                    "unix:///var/run/docker.sock"
                    "tcp://0.0.0.0:2375"
                ];
            };
            
        };
    };
}
