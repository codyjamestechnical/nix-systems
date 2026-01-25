{ pkgs, lib, ... }:

{

  # Containers
  virtualisation.oci-containers.containers = {

    "wg-exit-node" = {
      image = "ghcr.io/juhovh/tailguard:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/headscale/.env"
      ];
      volumes = [
        "/docker-data/wg-exit-node/config:/etc/wireguard:rw"
        "/docker-data/wg-exit-node/state:/tailguard/state:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=wg-exit-node"
        "--network=wg-exit-node-internal"
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--device=/dev/net/tun"
      ];
    };
  };
    
  # Networks
  systemd.services."docker-network-wg-exit-node-internal" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f wg-exit-node-internal";
    };
    script = ''
      docker network inspect wg-exit-node-internal || docker network create wg-exit-node-internal --ipv6
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
