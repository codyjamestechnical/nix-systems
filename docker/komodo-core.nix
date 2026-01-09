# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Containers
  virtualisation.oci-containers.containers = {

    "komodo-caddy" = {
      image = "caddy:latest";
      labels = {"komodo.skip" = "";};
      environmentFiles = [
        "/docker-data/Komodo/.env"
      ];
      volumes = [
        "/docker-data/Komodo/caddy:/data:rw"
        "/docker-data/Komodo/caddy/config:/config:rw"
        "/docker-data/Komodo/caddyfile:/etc/caddy/Caddyfile:ro"
        "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/ssl/privkey.pem:ro"
      ];
      ports = [
        "80:80/tcp"
        "443:443/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=caddy"
        "--network=komodo_komodo-internal"
      ];
    };

    "komodo-periphery" = {
      image = "ghcr.io/moghtech/komodo-periphery:latest";
      labels = {"komodo.skip" = "";};
      environmentFiles = [
        "/docker-data/Komodo/.env"
      ];
      volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          
          "/etc/komodo/ssl:/etc/komodo/ssl"
          "/etc/komodo/repos:/etc/komodo/repos"
          "/etc/komodo/stacks:/etc/komodo/stacks"
          "/var/secrets/komodo-passkey:/var/secrets/passkey"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=periphery"
        "--network=komodo_komodo-internal"
      ];
    };
    
    "komodo-core" = {
      image = "ghcr.io/moghtech/komodo-core:latest";
      labels = {"komodo.skip" = "";};
      environmentFiles = [
        "/docker-data/Komodo/.env"
      ];
      dependsOn = [
        "komodo-mongo"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=komodo-core"
        "--network=komodo_komodo-internal"
      ];
    };
    
    "komodo-mongo" = {
      image = "mongo";
      labels = {"komodo.skip" = "";};
      environmentFiles = [
        "/docker-data/Komodo/.env"
      ];
      volumes = [
        "/docker-data/Komodo/mongodb/config:/data/configdb:rw"
        "/docker-data/Komodo/mongodb/data:/data/db:rw"
      ];
      cmd = [ "--quiet" "--wiredTigerCacheSizeGB" "0.25" ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=mongo"
        "--network=komodo_komodo-internal"
      ];
    };
  };

  # Networks
  systemd.services."docker-network-komodo_komodo-internal" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f komodo_komodo-internal";
    };
    script = ''
      docker network inspect komodo_komodo-internal || docker network create komodo_komodo-internal --ipv6
    '';

    wantedBy = [ "multi-user.target" ];
  };

}
