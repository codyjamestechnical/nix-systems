# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, pkgs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./tailscale.nix
    ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot = false;
  boot.zfs.extraPools = [ "cjt_pool" ];
  services.zfs.autoScrub.enable = true;
  services.zfs.trim.enable = true;
  services.nfs.server.enable = true;
  
  networking.hostName = "jupiter"; # Define your hostname.
  networking.hostId = "8f150424";
  
  # Enable networking
  networking.networkmanager.enable = false;
  networking.dhcpcd.denyInterfaces = [ "macvtap0@*" ];
#  networking.defaultGateway = "10.0.30.1";
#  networking.bridges.br0.interfaces = ["enf1s0f1"];
#  networking.interfaces.br0 = {
#    useDHCP = false;
#    ipv4.addresses = [{
#      "address" = "10.0.30.2";
##      "prefixLength" = 24;
#    }];
#  };
  networking = {
    macvlans = {
      mv-libvirtd= {
        interface = "enp1s0f1";
        mode = "bridge";
      };
    };

    interfaces = {
      mv-libvirtd = {
        ipv4 = {
           addresses =  [
             {
               address = "10.0.30.50";
               prefixLength = 27;
             }
           ];
          
    #       routes = [
    #         {
    #           address = "10.0.30.50";
    #           prefixLength = 27;
    #           options = {
    #             dev = "macvlan_docker";
    #           };
    #         }
    #       ];
         };
       };
     };
  };
  
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  
  hardware.nvidia = {

    # Modesetting is needed for most Wayland compositors
    modesetting.enable = true;

    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    open = false;

    # Enable the nvidia settings menu
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  # services.xserver = {
  #   layout = "us";
  #   xkbVariant = "";
  # };

  # Enable sound with pipewire.
  # sound.enable = true;
  # hardware.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users={
    defaultUserShell = pkgs.zsh;
    groups = {
      acme.gid = 984;
      nextcloud.gid = 2011;
    };
    
    users.cody = {
      isNormalUser = true;
      description = "Cody";
      extraGroups = [ 
        "networkmanager" 
        "wheel"
        "docker"
        "thefuck"
        "libvirtd"
        "acme"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl { url = "https://github.com/codyjamestechnical.keys?1";})
      ];

      packages = with pkgs; [
      ];
    };

    users.container = {
      isSystemUser = true;
      group = "container";
      uid = 1002;
      shell = pkgs.zsh;
    };
  
    users.nextcloud = {
      isNormalUser = false;
      isSystemUser = true;
      group = "nextcloud";
      extraGroups = [
        "acme"
      ];
      uid = 999; 
    };

    groups = {
      container.gid = 1002;
    };
  };

  environment.variables = {
    EDITOR = "${pkgs.helix}/bin/helix";
  };

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    histSize = 10000;
    # plugins = [
    #   {
    #     name = "powerlevel10k";
    #     src = pkgs.zsh-powerlevel10k;
    #     file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    #   }
    #   {
    #     name = "powerlevel10k-config";
    #     src = ./p10k-config;
    #     file = ".p10k.zsh";
    #   }
    # ];
    # ohMyZsh = {
    #   enable = false;
    #   theme = "powerlevel10k/powerlevel10k";
    #   customPkgs = with pkgs; [
    #     zsh-powerlevel10k
    #   ];
    #   plugins = [
    #     "aliases"
    #     "git"
    #     "sudo"
    #     "docker"
        
    #   ];
    # };
  
    autosuggestions.enable = true;
    shellAliases = {
      runsrvc = "sudo systemctl start";
      stopsrvc = "sudo systemctl stop";
      resrvc = "sudo systemctl restart";
      ls = "lsd -lA";
      rebuild = "sudo nixos-rebuild switch";
      cat = "bat";

      
    };
  };
  # users.groups.nextcloud = {name = "nextcloud"; gid = 999; members=["nextcloud"];};
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    pv
    direnv
    wget
    dua
    git
    bfs
    exa
    pwgen
    helix
    vscode
    zsh-powerlevel10k
    nurl
    oh-my-zsh
    nerdfonts
    powerline-fonts
    docker-compose
    virt-manager
    vim
    lsd
    bat
  ];

  
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    banner = "Welcome to Jupiter Server!";
    settings = {
      PasswordAuthentication = true;
      UseDns = true;
      PermitRootLogin = "no";
    };
  };
  programs.mosh.enable = true;
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  services.cjt-tailscale = {
    enable = true;
    auth.key = "48f925e5d61f884cabb05bea126da0340cbd3335870f68d5";
  };

  #Nix daemon config
  nix = {
    # Automate garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    settings = {
      # Automate `nix store --optimise`
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "cody@31337.im";
  security.acme.certs."31337.im" = {
    domain = "*.31337.im";
    dnsProvider = "cloudflare";
    credentialsFile = "/var/lib/secrets/certs.secret";
    # We don't need to wait for propagation since this is a local DNS server
    dnsPropagationCheck = false;
    group = "acme";
    postRun = ''
      cp /var/lib/acme/31337.im/*.pem /var/lib/secrets/
    '';
  };
  ###### PLEX ######
  services.plex = {
    enable = true;
    dataDir = "/nix-container-data/plex";
    openFirewall = true;
    user = "plex";
    group = "plex";
    extraPlugins = [
      (builtins.path {
        name = "Audnexus.bundle";
        path = pkgs.fetchFromGitHub {
          owner = "djdembeck";
          repo = "Audnexus.bundle";
          rev = "v0.2.8";
          sha256 = "sha256-IWOSz3vYL7zhdHan468xNc6C/eQ2C2BukQlaJNLXh7E=";
        };
      })
    ];
  };
  
  containers.nextcloud = {
    autoStart = true;
    ephemeral = false;
    macvlans = ["enp1s0f1"];
    bindMounts = {
      "/var/lib/postgresql" = {
        hostPath = "/nix-container-data/nextcloud-db";
        isReadOnly = false;
      };
      "/var/lib/nextcloud/data" = {
        hostPath = "/nix-container-data/nextcloud";
        isReadOnly = false;
      };
    };

    config = 
      { config, pkgs, ... }:
      {
        imports = [
          ./tailscale.nix
        ];
        networking = {
          defaultGateway = "10.0.30.1";
          hostName = "nextcloud-00";
          hostId = "8f157122";
          interfaces."mv-enp1s0f1"= {
            ipv4.addresses = [
              {
                address = "10.0.30.102";
                prefixLength = 24;
              }
            ];
          };
        };

        services.cjt-tailscale = {
          enable = true;
          auth.key = "48f925e5d61f884cabb05bea126da0340cbd3335870f68d5";
          userspace = {
            enable = "true";
            state_dir = "/var/lib/tailscale/tailscaled-nextcloud";
          };
        };
      
        services.nextcloud = {
          enable = true;
          package = pkgs.nextcloud27;
          database.createLocally = true;
          configureRedis = true;
          hostName = "cloud.31337.im";
          config.dbtype = "pgsql";
          config.overwriteProtocol = "https";          
          config.adminpassFile = "${pkgs.writeText "adminpass" "Code156Lyoko"}";
          phpOptions = {
            upload_max_filesize = "16G";
            post_max_filesize = "16G";
          };

        };
        system.stateVersion = "23.05";

        networking.firewall = {
          enable = true;
          allowedTCPPorts = [ 80 ];
        };
        environment.etc."resolv.conf".text = "nameserver 8.8.8.8";
      };
  };
 
  ########## VIRTUALIZATION ###########

  ## Virtualization Options
  virtualisation = {

    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };
    
    docker = {
      enable = true;
      autoPrune ={
        flags = [ "--all" ];
        enable = true;
        dates = "weekly";
      };
    };
    
    podman = {
      enable = false;
       
      # Allows containers to talk to eachother.
      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };
  };

  # Docker Containers
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      it-tools = {
        image = "corentinth/it-tools";
        extraOptions = [
          "--hostname=it-tools"
          "--network=net_macvlan"
          "--ip=10.0.35.10"
        ];
      };
    };
    
  };  

  ### SDN CONTROLLERS ###
  systemd.services.start-dockerCompose-sdnControllers = 
    let 
      compose_file_location = "/docker-container-data/sdn-controllers/docker-compose.yml";
      composeBin = "${pkgs.docker-compose}/bin/docker-compose";
    in 
    {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      after = ["docker.service" "docker.socket"];
      script = "
          ${composeBin} -f ${compose_file_location} up -d --remove-orphans
      ";
    };

  ### TORRENT STACK ###
  systemd.services.start-dockerCompose-torrentStack = 
    let 
      compose_file_location = "/docker-container-data/torrent-stack/docker-compose.yml";
      composeBin = "${pkgs.docker-compose}/bin/docker-compose";
    in 
    {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      after = ["docker.service" "docker.socket"];
      script = "
          ${composeBin} -f ${compose_file_location} up -d --remove-orphans
      ";
    };

  ### METRICS COLLECTION ###  
  systemd.services.start-dockerCompose-metricsCollection = 
    let 
      compose_file_location = "/docker-container-data/metrics-collection/docker-compose.yml";
      composeBin = "${pkgs.docker-compose}/bin/docker-compose";
    in 
    {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      after = ["docker.service" "docker.socket"];
      script = "
          ${composeBin} -f ${compose_file_location} up -d --remove-orphans
      ";
    };

  ### AUTHENTIK ###
  systemd.services.start-dockerCompose-authentik = 
    let 
      compose_file_location = "/docker-container-data/authentik/docker-compose.yml";
      composeBin = "${pkgs.docker-compose}/bin/docker-compose";
    in 
    {
      serviceConfig.Type = "oneshot";
      wantedBy = [ "multi-user.target" ];
      after = ["docker.service" "docker.socket"];
      script = "
          ${composeBin} -f ${compose_file_location} up -d --remove-orphans
      ";
    };

  ### Create container macvlan network ###
  systemd.services.create-docker-macvlan-network = with config.virtualisation.oci-containers; 
    let 
      network_name = "net_macvlan";
      network_gateway = "10.0.35.1";
      network_subnet = "10.0.35.0/24";
      network_parent_interface = "enp1s0f1.35";
      network_starting_ip = "10.0.35.2";
      network_ip_range = "10.0.35.2/27";
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


}

