{ config, pkgs, ... }:

{

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

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
    eza
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
    openssl
    lsd
    bat
    ethtool
    networkd-dispatcher
    zip
    unzip
    cifs-utils
  ];

  # Enabled Services

  # OpenSSH daemon
  services.openssh.enable = true;

  #Tailscale
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";
  services.networkd-dispatcher = {
    enable = true;
    rules."50-tailscale" = {
      onState = ["routable"];
      script = ''
        "${pkgs.ethtool} NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ") | -K enp5s0 rx-udp-gro-forwarding on rx-gro-list off
      '';
    };
  };

  #ZSH
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    histSize = 10000;

    autosuggestions.enable = true;
    shellAliases = {
      runsrvc = "sudo systemctl start";
      stopsrvc = "sudo systemctl stop";
      resrvc = "sudo systemctl restart";
      ls = "lsd -lA";
      rebuild = "sudo nixos-rebuild switch";
      cat = "bat";
      dls = "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'";
      recompose = "sudo docker compose down --remove-orphans && sudo docker compose up -d";
      compose = "sudo docker compose up -d";
      decompose = "sudo docker compose down";
     
    };
  };

  #MOSH
  programs.mosh.enable = true;

  #TMUX
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  # Disable Firewall
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
