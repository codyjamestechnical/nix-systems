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

        # Netcup does not offer DHCPv6/SLAAC. IPv6 must be configured
        # statically from the /64 assigned in the netcup SCP, with the
        # link-local gateway fe80::1.
        networkmanager.ensureProfiles.profiles = {
            wan = {
                connection = {
                    id = "wan";
                    type = "ethernet";
                    interface-name = "ens3"; # verify with `ip a`
                    autoconnect = true;
                    autoconnect-priority = 100;
                };
                ipv4 = {
                    method = "auto";
                };
                ipv6 = {
                    method = "manual";
                    # Replace with your prefix from the netcup SCP:
                    address1 = "2a0a:4cc0:2000:34bf::1/64";
                    gateway = "fe80::1";
                };
            };
        };
    };

    ### TAILSCALE EXIT NODES -> WG VPN ###
    services.wg-exit-nodes = {

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
      wg-exit-node-obscura-chicago = {
        enable = true;
        tailscale_hostname = "obscura-chicago";
      };

    };

    ### CLEANUP TMP ON BOOT ###
    boot.tmp.cleanOnBoot = true;

    system.stateVersion = "26.05";
}
