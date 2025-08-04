{inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
        ./networking.nix
        ../../modules/core.nix
        ../../modules/acme.nix
        ../../modules/docker.nix
        ../../users/docker.nix
        ../../users/cody.nix
        ../../docker/netdata.nix
        ../../docker/komodo-peripherie.nix
        ../../docker/beszel-agent.nix
    ];


    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;

    # Network HostName
    networking.hostName = "komodo-server";

    system.stateVersion = "25.05";
}