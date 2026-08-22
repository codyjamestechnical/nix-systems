{ config, pkgs, ... }:

{
    ### PLASMA6 ###
    services.desktopManager.plasma6.enable = true; # Enable Plasma desktop
    services.displayManager.plasma-login-manager.enable = true; # Enable Plasma login manager

    ### FLATPAK ###
    services.flatpak = {
        enable = true; # Enable Flatpak support

        # Automatically update flatpaks on a schedule
        update.auto = {
          enable = true;
          onCalendar = "weekly";
        };

        packages = [
          # Add flatpak app IDs here, e.g.:
          # { appId = "org.mozilla.firefox"; origin = "flathub"; }
         "io.github.kolunmi.Bazaar"
         "com.bitwarden.desktop"
         "com.fastmail.Fastmail"
         "dev.zed.Zed"
         "org.signal.Signal"
         
        ];
      };

    

    ### SYSTEM PACKAGES ###
    environment.systemPackages = with pkgs; [
      # KDE Utilities
      kdePackages.kcalc # Calculator
      kdePackages.kcharselect # Character map
      kdePackages.kclock # Clock app
      kdePackages.kcolorchooser # Color picker
      kdePackages.kolourpaint # Simple paint program
      kdePackages.ksystemlog # System log viewer
      kdiff3 # File/directory comparison tool
      kdePackages.isoimagewriter # Write hybrid ISOs to USB
      kdePackages.partitionmanager # Disk and partition management
      hardinfo2 # System benchmarks and hardware info
      wayland-utils # Wayland diagnostic tools
      wl-clipboard # Wayland copy/paste support
      vlc # Media player
    ];

    ### UNLOCK KDE WALLET WITH LUKS PASSWORD ###
    boot.initrd.systemd.enable = true;
    systemd.services.plasmalogin.serviceConfig.KeyringMode = "inherit";
    security.pam.services.plasmalogin-autologin.rules.auth = {
      systemd_loadkey = {
        order = 0;
        control = "optional";
        modulePath = "${pkgs.systemd}/lib/security/pam_systemd_loadkey.so";
      };
      plasmalogin = {
        order = 1;
        control = "include";
        modulePath = "plasmalogin";
      };
    };
    
}