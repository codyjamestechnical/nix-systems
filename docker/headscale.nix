# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Containers
  virtualisation.oci-containers.containers = {

    "headplane-caddy" = {
      image = "caddy:latest";
      labels = {"komodo.skip" = "";};
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
        "/docker-data/headscale/caddy:/data:rw"
        "/docker-data/headscale/caddy/config:/config:rw"
        "/docker-data/headscale/caddyfile:/etc/caddy/Caddyfile:ro"
        "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/ssl/privkey.pem:ro"
      ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=caddy"
        "--network=headscale-internal"
      ];
    };

    "headplane-tailscale" = {
      image = "tailscale/tailscale:latest";
      labels = {"komodo.skip" = "";};
      dependsOn = [
        "headscale"
        "headplane-caddy"
      ];
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "/docker-data/headscale/tailscale:/var/lib"
      ];
      log-driver = "jounald";
      extraOptions = [
        "--network-alias=headplane-tailscale"
        "--network=container:headplane-caddy"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };

    "headscale" = {
      image = "ghcr.io/juanfont/headscale:latest";
      labels = {
        "komodo.skip" = "";
        "me.tale.headplane.target" =  "headscale"; 
      };
      ports = [
        "3478:3478/udp"
        "50443:50443"
        "443:443"
        "80:80"
      ];
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
          "/docker-data/headscale/configs/headscale:/etc/headscale"
          "/docker-data/headscale/data/headscale:/var/lib/headscale"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=headscale"
        "--network=headscale-internal"
      ];
    };

    "headplane" = {
      image = "ghcr.io/tale/headplane:0.6.2-beta.3";
      dependsOn = [
        "headscale"
      ];
      volumes = [
        "/docker-data/headscale/data/headscale:/var/lib/headscale"
        "/docker-data/headscale/configs/headscale:/etc/headscale"
        "/docker-data/headscale/configs/headplaene:/etc/headplane"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      environmentFiles = [
        "/docker-data/headscale/.env.headplane"
      ];
    }

  # Networks
  systemd.services."docker-network-headscale-internal" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f headscale-internal";
    };
    script = ''
      docker network inspect headscale-internal || docker network create headscale-internal --ipv6
    '';

    wantedBy = [ "multi-user.target" ];
  };

}
