{ inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    ### NETWORKING ###
    networking = {
        hostName = "deimos-server";
        networkmanager.enable = true;
    };

    ### TAILSCALE EXIT NODES -> WG VPN ###
    # services.wg-exit-nodes = {

    #   # Obscura VPN Amsterdam
    #   wg-exit-node-obscura-amsterdam = {
    #     enable = true;
    #     tailscale_hostname = "obscura-amsterdam";
    #   };

    #   # Obscura VPN Atlanta
    #   wg-exit-node-obscura-atlanta = {
    #     enable = true;
    #     tailscale_hostname = "obscura-atlanta";
    #   };

    #   # Obscura VPN Atlanta
    #   wg-exit-node-obscura-chicago = {
    #     enable = true;
    #     tailscale_hostname = "obscura-chicago";
    #   };

    # };

    ### CLEANUP TMP ON BOOT ###
    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "26.05";
}
