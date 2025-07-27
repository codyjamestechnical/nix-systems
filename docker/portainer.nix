{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            portainer = {
                image = "portainer/portainer-ce:latest";
                ports = [
                    "0.0.0.0:443:9443" 
                    "0.0.0.0:8000:8000"
                ];
                log-driver = "local";
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/var/lib/acme/31337.im:/ssl"
                    "/proc:/proc"
                    "/docker-data/portainer:/data"
         
                ];
                environment = {
                    SSLCERT = "/ssl/cert.pem";
                    SSLKEY = "/ssl/key.pem";
                };
                labels = {"komodo.skip" = "";};
            };
        };
    };
}