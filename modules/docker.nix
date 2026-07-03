{ config, pkgs, ... }:
{
  # Create docker-data directory
  systemd.tmpfiles.rules = [
    "d /docker-data 0770 docker docker -"
  ];

  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      acme.gid = 984;
    };

    users.docker = {
      isNormalUser = false;
      isSystemUser = true;
      group = "docker";
      extraGroups = [
        "acme"
      ];
    };
  };

  ## Virtualization Options
  virtualisation = {
    docker = {
      enable = true;
      #     enable = true;
      #     setSocketVariable = true;
      #     daemon.settings = {
      #         ipv6 = true;
      #         hosts = [
      #             "unix:///run/user/1000/docker.sock"
      #             "tcp://0.0.0.0:2375"
      #         ];
      #     };
      # };

      enableNvidia = false;

      autoPrune = {
        flags = [ "--all" ];
        enable = true;
        dates = "weekly";
      };

      daemon.settings = {
        userland-proxy = false;
        experimental = true;
        metrics-addr = "0.0.0.0:9323";
        ip-forward = true;
        ipv6 = true;
        ip6tables = true;   # needed for IPv6 NAT/filtering on modern Docker
        fixed-cidr-v6 = "fd00::/80";
        "hosts" = [
          "unix:///var/run/docker.sock"
          "tcp://0.0.0.0:2375"
        ];
      };

    };
  };
}
