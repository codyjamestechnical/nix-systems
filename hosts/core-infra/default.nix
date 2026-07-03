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

    networking.firewall = {
      enable = false;

      # both TCP and UDP for every port you listed
      allowedTCPPorts = [ 80 443 3478 41641 41642 ];
      allowedUDPPorts = [ 80 443 3478 41641 41642 ];

      # ICMP (echo/ping + PMTU)
      allowPing = true;

      # port-preserving 1:1 NAT so the tailscale container's UDP port
      # stays stable in both directions (beats docker's --random-fully MASQUERADE)
      # extraCommands = ''
      #   iptables -t nat -A PREROUTING  -i eth0 -p udp --dport 41642 \
      #     -j DNAT --to-destination 172.20.0.2:41642
      #   iptables -t nat -I POSTROUTING 1 -s 172.20.0.2 -p udp --sport 41642 \
      #     -o eth0 -j SNAT --to-source 5.161.235.16:41642
      # '';

      # extraStopCommands = ''
      #   iptables -t nat -D PREROUTING  -i eth0 -p udp --dport 41642 \
      #     -j DNAT --to-destination 172.20.0.2:41642 2>/dev/null || true
      #   iptables -t nat -D POSTROUTING -s 172.20.0.2 -p udp --sport 41642 \
      #     -o eth0 -j SNAT --to-source 5.161.235.16:41642 2>/dev/null || true
      # '';
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
