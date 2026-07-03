{ inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ./networking.nix
        ../../modules/core.nix
        ../../docker/komodo-core.nix
        ../../docker/beszel-agent.nix
        ../../docker/headscale.nix
        ../../modules/acme.nix
        ../../modules/docker.nix
        ../../docker/wg-exit-nodes.nix
        ../../docker/arkeep-agent.nix
    ];

    boot.kernel.sysctl = {
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv6.conf.default.forwarding" = 1;
        # Accept Router Advertisements even while forwarding is on,
        # so the host still gets its own IPv6 via SLAAC.
        "net.ipv6.conf.eth0.accept_ra" = 2;
      };

      virtualisation.docker = {
        daemon.settings = {
          ipv6 = true;
          # A ULA (or your delegated GUA prefix) used as the default
          # pool for user-defined networks that don't specify a subnet.
          # "fixed-cidr-v6" = "2a01:4ff:f0:f9f1::/64";
          experimental = true;
          ip6tables = true;   # needed for IPv6 NAT/filtering on modern Docker
        };
      };
    services.wg-exit-nodes = {
      wg-exit-node-proton-toronto = {
        enable = true;
        tailscale_hostname = "proton-toronto";
      };

      wg-exit-node-proton-amsterdam = {
        enable = true;
        tailscale_hostname = "proton-amsterdam";
      };

      wg-exit-node-obscura-atlanta = {
        enable = true;
        tailscale_hostname = "obscura-atlanta";
      };

    };
    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;

    # Network HostName
    networking.hostName = "core-infra";

    # fileSystems."/backup" = {
    #     device = "//u429456.your-storagebox.de/backup";
    #     fsType = "cifs";
    #     options = let
    #     # this line prevents hanging on network split
    #     automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,file_mode=0750,dir_mode=0750,uid=995,gid=131,mfsymlinks,seal,noperm,nobrl";

    #     in ["${automount_opts},credentials=/etc/nixos/secrets/smb-secrets"];
    # };

    #ZSH
    programs.zsh.shellAliases = {
        headscale = "docker exec -it headscale-server headscale";
    };
    system.stateVersion = "25.11";
}
