{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            portainer-master = {
                image = "portainer/portainer-ce:latest";
                ports = [
                    "0.0.0.0:443:9443" 
                    "0.0.0.0:8000:8000"
                ];
                log-driver = "local";
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
                    "/var/lib/acme/31337.im/key.pem:/ssl/key.pem:ro"
                    "/proc:/proc"
                    "/docker-data/portainer:/data"
         
                ];
                cmd = [
                    "--sslcert" 
                    "/ssl/cert.pem" 
                    "--sslkey" 
                    "/ssl/key.pem"
                ];
                labels = {"komodo.skip" = "";};
            };
        };
    };
}

