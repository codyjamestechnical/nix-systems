{ inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ./networking.nix
        ../../modules/core.nix
        ../../docker/komodo-periphery.nix
        ../../docker/beszel-agent.nix
        ../../docker/headscale.nix
        ../../modules/acme.nix
        ../../modules/docker.nix
    ];


    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;

    # Network HostName
    networking.hostName = "headscale-server";

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
        headscale = "docker exec -it headscale headscale";
    };
    system.stateVersion = "25.11";
}