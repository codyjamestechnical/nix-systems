{ inputs, config, pkgs, ... }:
{
    imports = [
        ./hardware-configuration.nix

        ../../modules/core.nix
        ../../modules/acme.nix
        ../../modules/docker.nix
        ../../users/docker.nix
        ../../users/cody.nix
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    #Network
    networking.hostName = "mars-server";
    networking.hostId = "deadb33f";

    # ZFS Pool Setup
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportRoot = false;
    boot.zfs.extraPools = [ "cjt_pool" ];
    services.zfs.autoScrub.enable = true;
    services.zfs.trim.enable = true;

    #Samba Shares
    services.samba = {
        enable = true;
        package = pkgs.samba4Full;
        openFirewall = true;
        settings = {
            global = {
                "workgroup" = "WORKGROUP";
                "server string" = "mars-server";
                "netbios name" = "mars-server";
                "security" = "user";
                #"use sendfile" = "yes";
                # "max protocol" = "smb3";
                # note: localhost is the ipv6 localhost ::1
                "hosts allow" = "10.0.10. 10.0.30. 127.0.0.1 localhost";
                "hosts deny" = "0.0.0.0/0";
                "guest account" = "nobody";
                "map to guest" = "bad user";
                "log file" = "/var/log/samba/client.%I";
                "log level" = "2";
                "wins support" = "yes";
                "local master" = "yes";
                "preferred master" = "yes";
                "server min protocol" = "SMB3_00";
            };
            "docker-data" = {
                "path" = "/docker-data";
                "browseable" = "yes";
                "read only" = "no";
                "guest ok" = "yes";
                "create mask" = "0777";
                "directory mask" = "0777";
                "force user" = "cody";
            };
            "Movies" = {
                "path" = "/mnt/cjt_pool/Media-Files/TV";
                "browseable" = "yes";
                "read only" = "no";
                "guest ok" = "yes";
                "create mask" = "0777";
                "directory mask" = "0777";
                "force user" = "cody";
            };
            "TV-Shows" = {
                "path" = "/mnt/cjt_pool/Media-Files/TV";
                "browseable" = "yes";
                "read only" = "no";
                "guest ok" = "yes";
                "create mask" = "0777";
                "directory mask" = "0777";
                "force user" = "cody";
            };
        };
    };

# services.avahi = {
#     publish.enable = true;
#     publish.userServices = true;
#     publish.hinfo = true;
#     # ^^ Needed to allow samba to automatically register mDNS records (without the need for an `extraServiceFile`
#     nssmdns4 = true;
#     nssmdns6 = true;
#     ipv6 = true;
#     hostName = "mars";
#     # ^^ Not one hundred percent sure if this is needed- if it aint broke, don't fix it
# 	enable = true;
#     openFirewall = true;
# };

    services.avahi = {
        enable = true;
        nssmdns4 = true;
        nssmdns6 = true;
        publish = {
            enable = true;
            addresses = true;
            domain = true;
            hinfo = true;
            userServices = true;
            workstation = true;
        };
        extraServiceFiles = {
        smb = ''
            <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
            <name replace-wildcards="yes">%h</name>
            <service>
                <type>_smb._tcp</type>
                <port>445</port>
            </service>
            </service-group>
        '';
        };
  };  


    services.samba-wsdd = {
        enable = true;
        openFirewall = true;
    };

  
    ### Create container macvlan network ###
    systemd.services.create-docker-macvlan-network = with config.virtualisation.oci-containers; 
    let 
        network_name = "net_macvlan";
        network_gateway = "10.0.35.1";
        network_subnet = "10.0.35.0/24";
        network_parent_interface = "enp5s0.35";
        network_starting_ip = "10.0.35.2";
        network_ip_range = "10.0.35.0/27";
        network_other_options = "";
        backendBin = "${pkgs.docker}/bin/${backend}";
    in 
    {
        enable = true;
        serviceConfig.Type = "oneshot";
        wantedBy = [ "basic.target" ];
        after = ["docker.service" "docker.socket"];
        script = "
            ${backendBin} network inspect ${network_name} >/dev/null 2>&1|| \
            ${backendBin} network create --subnet=${network_subnet} --gateway=${network_gateway} --aux-address 'host=${network_starting_ip}' --ip-range ${network_ip_range} --driver=macvlan -o parent=${network_parent_interface} ${network_name}
            ";
    };

    # Docker Containers
    virtualisation.oci-containers = {
        backend = "docker";
        containers = {
            komodo-peripherie = {
                image = "ghcr.io/mbecker20/periphery:latest";
                ports = ["0.0.0.0:8120:8120"];
                log-driver = "local";
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock"
                    "/proc:/proc"
                    "/etc/komodo/ssl:/etc/komodo/ssl"
                    "/etc/komodo/repos:/etc/komodo/repos"
                    "/etc/komodo/stacks:/etc/komodo/stacks"
                    "/var/secrets/komodo-passkey:/var/secrets/passkey"
                ];
                environment = {
                    PERIPHERY_SSL_ENABLED = "true";
                    PERIPHERY_INCLUDE_DISK_MOUNTS = "/etc/hostname";
                    PERIPHERY_PASSKEYS_FILE = "/var/secrets/passkey";
                };
                labels = {"komodo.skip" = "";};
            };

            beszel-agent = {
                image = "henrygd/beszel-agent";
                serviceName = "beszel-agent";
                extraOptions = ["--network=host"];
                volumes = [
                    "/var/run/docker.sock:/var/run/docker.sock:ro"
                    "/docker-data/.beszel:/extra-filesystems/Docker_Data:ro"
                ];
                environment = {
                    PORT = "45876";
                    KEY = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ+L7U8f/hxIu5fj0fTVT2ngKHo4Kv+SaSdEbat25cA";
                };
                labels = {"komodo.skip" = "";};
            };
        };
        
    };




    system.stateVersion = "24.11";
}