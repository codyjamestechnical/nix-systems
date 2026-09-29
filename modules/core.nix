{ config, pkgs, ... }:

{
  imports = [
    ../users/cody.nix
  ];

  ### ENABLE NETWORK MANAGER ###
  networking.networkmanager.enable = true;

  ### ENABLE ZRAM SWAP ###
  zramSwap.enable = true;

  ### TIMEZONE ###
  time.timeZone = "America/New_York";

  ### LOCALE ###
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

  ### ALLOW UNFREE PACKAGES ###
  nixpkgs.config.allowUnfree = true;

  ### SYSTEM PACKAGES ###
  environment.systemPackages = with pkgs; [
    iperf3
    pv
    direnv
    wget
    dua
    git
    htop
    bfs
    eza
    pwgen
    helix
    zsh-powerlevel10k
    nurl
    oh-my-zsh
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
    superfile
    smartmontools
  ];

  ### ZSH ###
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    histSize = 10000;

    autosuggestions.enable = true;
    shellAliases = {
      # Systemctl Service Management
      startsvc = "sudo systemctl start";
      stopsvc = "sudo systemctl stop";
      restartsvc = "sudo systemctl restart";
      logsvc = "sudo journalctl -xeu";

      # File system aliases
      ls = "ls -lA";
      cat = "bat";
      spf = "superfile";

      # Speed Tests
      speed-atlanta = "iperf3 -c atl.speedtest.clouvider.net -p 5200-5209 && ping -U -c 10 atl.speedtest.clouvider.net";
      speed-germany = "iperf3 -c speedtest.fra1.de.leaseweb.net -p 5201-5210 && ping -U -c 10 speedtest.fra1.de.leaseweb.net";
      speed-amsterdam = "iperf3 -c ams.speedtest.clouvider.net -p 5200-5209 && ping -U -c 10 ams.speedtest.clouvider.net";
      speed-canada = "iperf3 -c speedtest.mtl2.ca.leaseweb.net -p 5201-5210 && ping -U -c 10 speedtest.mtl2.ca.leaseweb.net";

      # Pull latest git changes and rebuild switch NixOS with flake
      rebuild = "sudo git -C /etc/nixos/nix-systems pull && sudo nixos-rebuild switch --flake '/etc/nixos/nix-systems#${config.networking.hostName}'";

    };
  };

  ### MOSH ###
  programs.mosh = {
    enable = true;
  };

  ### TMUX ###
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  # Create a symlink from /usr/libexec/platform-python to the Python executable
  systemd.tmpfiles.rules = [
    "L+ /usr/libexec/platform-python - - - - ${pkgs.python3Minimal}/bin/python3"
  ];

  ### FIREWALL ###
  networking.firewall = {
    enable = true;
    allowPing = true;
  };

  ### STORAGE OPTIMIZATION ###
  # Enable auto-optimisation of the Nix store
  nix.optimise = {
    automatic = true;
    dates = [ "05:00" ];
  };

  ### GARBAGE COLLECTION AUTOMATION ###
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  ### CLEANUP TMP ON BOOT ###
  boot.tmp.cleanOnBoot = true;
    
  ### NIX SETTINGS ###
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
}
