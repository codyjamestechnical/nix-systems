{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            portainer-agent = {
                image = "portainer/agent:latest";
                ports = [
                    "0.0.0.0:9001:9001" 
                ];
                log-driver = "local";
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/var/lib/docker/volumes:/var/lib/docker/volumes"
                    "/:/host"
                ];
                labels = {"komodo.skip" = "";};
            };
        };
    };
}
