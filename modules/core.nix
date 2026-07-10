{ config, pkgs, ... }:

{
  imports = [
    ./acme.nix
    ./docker.nix
    ../users/cody.nix
  ];

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

  ];

  ### OpenSSH DEAMON ###
  services.openssh = {
    enable = true;
  };

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
      ls = "lsd -lA";
      cat = "bat";

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
  # Create secrets directory
  systemd.tmpfiles.rules = [
    "L+ /usr/libexec/platform-python - - - - ${pkgs.python3Minimal}/bin/python3"
  ];

  ### FIREWALL ###
  networking.firewall = {
    enable = true;
    allowPing = true;
  };

  ### NIX SETTINGS ###
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
}
