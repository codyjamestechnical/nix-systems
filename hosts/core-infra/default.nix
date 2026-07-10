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
        ../../docker/dockhand.nix
    ];

    ### NETWORKING ###
    networking = {
        hostName = "core-infra";
    };

    ### IPv6 SLAAC ###
    boot.kernel.sysctl = {
        # Accept Router Advertisements even while forwarding is on,
        # so the host still gets its own IPv6 via SLAAC.
        "net.ipv6.conf.eth0.accept_ra" = 2;
      };

    ### TAILSCALE EXIT NODES -> WG VPN ###
    services.wg-exit-nodes = {

      # Proton VPN Toronto
      wg-exit-node-proton-toronto = {
        enable = true;
        tailscale_hostname = "proton-toronto";
      };

      # Proton VPN Amsterdam
      wg-exit-node-proton-amsterdam = {
        enable = true;
        tailscale_hostname = "proton-amsterdam";
      };

      # Obscura VPN Atlanta
      wg-exit-node-obscura-atlanta = {
        enable = true;
        tailscale_hostname = "obscura-atlanta";
      };

    };

    ### CLEANUP TMP ON BOOT ###
    boot.tmp.cleanOnBoot = true;

    # fileSystems."/backup" = {
    #     device = "//u429456.your-storagebox.de/backup";
    #     fsType = "cifs";
    #     options = let
    #     # this line prevents hanging on network split
    #     automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,file_mode=0750,dir_mode=0750,uid=995,gid=131,mfsymlinks,seal,noperm,nobrl";

    #     in ["${automount_opts},credentials=/etc/nixos/secrets/smb-secrets"];
    # };

    system.stateVersion = "25.11";
}
