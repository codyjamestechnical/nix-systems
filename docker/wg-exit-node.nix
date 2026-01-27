{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "wg-exit-node";
    network_name = "wg-exit-node-internal";
    base_dir = "/docker-data/wg-exit-node";
    secrets_dir = "/etc/nixos/secrets";
    tailscale_tags = "tag:core-infra";
  };
in
{

  # Containers
  virtualisation.oci-containers.containers = {

    ### WIREGUARD EXIT NODE ###
    "${cfg.service_name}" = {
      image = "ghcr.io/juhovh/tailguard:latest";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/config:/etc/wireguard:rw"
        "${cfg.base_dir}/state:/tailguard/state:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=wg-exit-node"
        "--network=${cfg.network_name}"
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--device=/dev/net/tun"
      ];
      environment = {
        TS_STATE_DIR = "/var/lib/tailscale";
        TS_USERSPACE = "false";
        TS_LOGIN_SERVER = "https://headscale.cjtech.io";
      };
    };
  };

  ### NETWORK ###
  systemd.services."docker-network-${cfg.network_name}" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f ${cfg.network_name}";
    };
    script = ''
      docker network inspect ${cfg.network_name} || docker network create ${cfg.network_name} --ipv6
    '';

    wantedBy = [ "multi-user.target" ];
  };

}
