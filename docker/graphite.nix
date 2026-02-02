{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "graphite";
    network_name = "graphite-internal";
    base_dir = "/docker-data/graphite";
    secrets_dir = "/etc/nixos/secrets";
    tailscale_tags = "tag:core-infra";
  };
in
{

  # Containers
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### WIREGUARD EXIT NODE ###
    "${cfg.service_name}" = {
      image = "graphiteapp/graphite-statsd:latest";
      labels = {
        "komodo.skip" = "";
      };
      ports = [
        "8081:80"
        "2003-2004:2003-2004"
        "2023-2024:2023-2024/udp"
        "8125:8125/udp"
        "8126:8126"
        "8080:8080"
      ];
      environmentFiles = [
        # "/docker-data/.env"
        # "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/config:/opt/graphite/conf:rw"
        "${cfg.base_dir}/storage:/opt/graphite/storage:rw"
        "${cfg.base_dir}/logs:/opt/graphite/logs:rw"
        "${cfg.base_dir}/redis:/var/lib/redis:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=${cfg.service_name}"
        "--network=${cfg.network_name}"
      ];
      environment = {
        GRAPHITE_TIME_ZONE = "America/New_York";
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