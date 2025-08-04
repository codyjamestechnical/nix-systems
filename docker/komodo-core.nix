# Auto-generated using compose2nix v0.3.1.
{ pkgs, lib, ... }:

{
  # Containers
  virtualisation.oci-containers.containers."komodo-caddy" = {
    image = "caddy:latest";
    environmentFiles = [
      "/docker-data/Komodo/.env"
    ];
    volumes = [
      "/docker-data/komodo/caddy:/data:rw"
      "/docker-data/komodo/caddy/config:/config:rw"
      "/docker-data/komodo/caddyfile:/etc/caddy/Caddyfile:rw"
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
  
  virtualisation.oci-containers.containers."komodo-core" = {
    image = "ghcr.io/moghtech/komodo-core:latest";
    environmentFiles = [
      "/docker-data/Komodo/.env"
    ];
    volumes = [
      "/docker-data/komodo/repo-cache:/repo-cache:rw"
    ];
    labels = {
      "komodo.skip" = "";
    };
    dependsOn = [
      "komodo-mongo"
    ];
    log-driver = "local";
    extraOptions = [
      "--network-alias=komodo-core"
      "--network=komodo_komodo-internal"
    ];
  };
  
  virtualisation.oci-containers.containers."komodo-mongo" = {
    image = "mongo";
    environmentFiles = [
      "/docker-data/Komodo/.env"
    ];
    volumes = [
      "/docker-data/komodo/mongodb/config:/data/configdb:rw"
      "/docker-data/komodo/mongodb/data:/data/db:rw"
    ];
    cmd = [ "--quiet" "--wiredTigerCacheSizeGB" "0.25" ];
    labels = {
      "komodo.skip" = "";
    };
    log-driver = "local";
    extraOptions = [
      "--network-alias=mongo"
      "--network=komodo_komodo-internal"
    ];
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
