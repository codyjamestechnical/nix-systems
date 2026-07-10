{ config, pkgs, ... }:
{
  imports = [
    ../users/docker.nix # Import docker user
  ];

  # Create docker-data directory
  systemd.tmpfiles.rules = [
    "d /docker-data 0770 docker docker -"
  ];

  ### ZSH SHELL ALIASES ###
  programs.zsh.shellAliases = {
    # docker ps with formatted output
    dps = "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'";

    # docker exec
    dexec = "sudo docker exec -it";

    # docker compose up/down
    compose = "sudo docker compose up -d";
    recompose = "sudo docker compose down --remove-orphans && sudo docker compose up -d"; # down and remove orphans, then up
    decompose = "sudo docker compose down";
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
