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

    networking.hostName = "mars-server";

    #ZFS Pool Setup
    # boot.supportedFilesystems = [ "zfs" ];
    # boot.zfs.forceImportRoot = false;
    # boot.zfs.extraPools = [ "cjt_pool" ];
    # services.zfs.autoScrub.enable = true;
    # services.zfs.trim.enable = true;

    #Samba Shares
    # services.samba = {
    #     enable = true;
    #     enableNmbd = false;
    #     enableWinbindd = false;
    #     extraConfig = ''
    #         guest account = cody
    #         map to guest = Bad User
    #         create mask = 0777
    #         force create mode = 0777
    #         directory mask = 0777
    #         force directory mode = 0777
    #         load printers = no
    #         printcap name = /dev/null
    #         log file = /var/log/samba/client.%I
    #         log level = 2
    #     '';
    #     shares = {
    #         TV-Shows = {
    #             "path" = "/mnt/cjt_pool/Media-Files/TV";
    #             "guest ok" = "yes";
    #             "read only" = "no";
    #         };

    #         Movies = {
    #             "path" = "/mnt/cjt_pool/Media-Files/Movies";
    #             "guest ok" = "yes";
    #             "read only" = "no";
    #         };

    #         Downloads = {
    #             "path" = "/mnt/cjt_pool/Media_Files/Downloads";
    #             "guest ok" = "yes";
    #             "read only" = "no";
    #             "browsable" = "yes";
    #         };

    #         Docker = {
    #             "path" = "/mnt/cjt_pool/Container Data/docker_data";
    #             "guest ok" = "yes";
    #             "read only" = "no";
    #         };      
    #     };
    # };

services.samba = {
    enable = true;
    openFirewall = true;
    nmbd.enable = true;
    smbd.enable = true;
    winbindd.enable = true;
    nsswins = true;
    settings = {
        global = {
            "workgroup" = "WORKGROUP";
            "server string" = "mars";
            "netbios name" = "mars";
            "security" = "user";
            #"use sendfile" = "yes";
            # "max protocol" = "smb3";
            # note: localhost is the ipv6 localhost ::1
            # "hosts allow" = "0.0.0.0/0";
            # "hosts deny" = "0.0.0.0/0";
            "guest account" = "cody";
            "map to guest" = "bad user";
            "log file" = "/var/log/samba/client.%I"
            "log level = 2"
        };
        "docker-data" = {
            "path" = "/home/cody";
            "browseable" = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0777";
            "directory mask" = "0777";
            "force user" = "1000";
            "force group" = "100";
        };
        # "Movies" = {
        #     "path" = "/mnt/cjt_pool/Media-Files/TV";
        #     "browseable" = "yes";
        #     "read only" = "no";
        #     "guest ok" = "yes";
        #     "create mask" = "0777";
        #     "directory mask" = "0777";
        #     "force user" = "1000";
        #     "force group" = "100";
        # };
        # "TV-Shows" = {
        #     "path" = "/mnt/cjt_pool/Media-Files/TV";
        #     "browseable" = "yes";
        #     "read only" = "no";
        #     "guest ok" = "yes";
        #     "create mask" = "0777";
        #     "directory mask" = "0777";
        #     "force user" = "1000";
        #     "force group" = "100";
        # };
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
        serviceConfig.Type = "oneshot";
        wantedBy = [ "multi-user.service" ];
        after = ["docker.service" "docker.socket"];
        script = "
            ${backendBin} network inspect ${network_name} >/dev/null 2>&1|| \
            ${backendBin} network create --subnet=${network_subnet} --gateway=${network_gateway} --aux-address 'host=${network_starting_ip}' --ip-range ${network_ip_range} --driver=macvlan -o parent=${network_parent_interface} ${network_name}
            ";
    };
 





    system.stateVersion = "24.11";
}