{ inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix

        # MODULES
        ../../modules/core.nix ## CORE

    ];

    ### NETWORKING ###
    networking = {
        hostName = "core-infra";
    };

    ### CLEANUP TMP ON BOOT ###
    boot.tmp.cleanOnBoot = true;

    modules.app-manager.enable = true;

    system.stateVersion = "26.05";
}