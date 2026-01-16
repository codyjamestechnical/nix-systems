{ config, pkgs, ...}:
{
    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            beszel-agent = {
                image = "henrygd/beszel-agent";
                serviceName = "beszel-agent";
                extraOptions = ["--network=host"];
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock:ro"
                    "/docker-data/.beszel:/extra-filesystems/Docker_Data:ro"
                ];
                environmentFiles = [
                    "/etc/nixos/secrets/beszel-agent.env"
                ];
                # environment = {
                #     PORT = "45876";
                #     KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+L7U8f/hxIu5fj0fTVT2ngKHo4Kv+SaSdEbat25cA";
                # };
                labels = {"komodo.skip" = "";};
            };
        };
    };
}