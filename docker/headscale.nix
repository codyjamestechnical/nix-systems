{ pkgs, lib, ... }:

{

  security.acme.certs."cjtech.io" = {
    domain = "*.cjtech.io";
    dnsProvider = "cloudflare";
    environmentFile = "/etc/nixos/secrets/cloudflare-token";
    dnsPropagationCheck = true;
  };

  # Containers
  virtualisation.oci-containers.containers = {

    "headscale-caddy" = {
      image = "caddy:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
        "/docker-data/headscale/caddy/data:/data:rw"
        "/docker-data/headscale/caddy/config:/config:rw"
        "/docker-data/headscale/configs/caddy/caddyfile.txt:/etc/caddy/Caddyfile:ro"
        "/var/lib/acme/31337.im/fullchain.pem:/ssl/fullchain.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/ssl/privkey.pem:ro"
      ];
      log-driver = "journald";
      ports = [
        
      ];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=caddy"
        "--network=headscale-internal"
      ];
    };

    "headscale-tailscale" = {
      image = "tailscale/tailscale:latest";
      labels = {
        "komodo.skip" = "";
      };
      dependsOn = [
        "headscale"
        "headplane-caddy"
      ];
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "/docker-data/headscale/data/tailscale:/var/lib/tailscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=container:headplane-caddy"
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
      ];
    };

    "headscale" = {
      image = "ghcr.io/juanfont/headscale:v0.27.2-rc.1";
      labels = {
        "komodo.skip" = "";
        "me.tale.headplane.target" = "headscale";
      };
      ports = [
        "443:443"
        "80:80"
        "3478:3478/udp"
        "50443:50443"
        "50443:50443/udp"
      ];
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
        "/docker-data/headscale/configs/headscale:/etc/headscale:rw"
        "/docker-data/headscale/data/headscale/lib:/var/lib/headscale:rw"
        "/docker-data/headscale/data/headscale/run:/var/run/headscale:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=headscale headscale.cjtech.io"
        "--network=headscale-internal"
        "--health-cmd='CMD headscale health'"
        "--dns=1.1.1.1"
      ];
      cmd = [ "serve" "--config" "/etc/headscale/config.yaml" ];
    };

    "headplane" = {
      image = "ghcr.io/tale/headplane:0.6.2-beta.3";
      dependsOn = [
        "headscale"
      ];
      volumes = [
        "/docker-data/headscale/data/headscale/lib:/var/lib/headscale:rw"
        "/docker-data/headscale/configs/headscale:/etc/headscale:rw"
        "/docker-data/headscale/configs/headplane:/etc/headplane:rw"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=headscale"
        "--network=headscale-internal"
        "--dns=1.1.1.1"
      ];
    };
  };

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
