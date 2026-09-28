{ config, pkgs, ... }:

{
  ### ENABLE WIRELESS NETWORK ###
  networking.wireless.enable = true;

  ### ENABLE BLUETOOTH ###
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  ### PLASMA6 ###
  services.desktopManager.plasma6.enable = true; # Enable Plasma desktop
  services.displayManager.plasma-login-manager.enable = true; # Enable Plasma login manager

  ### Enable FWUPD ###
  services.fwupd.enable = true;

  ### ENABLE APP MANAGER ###
  modules.app-manager.enable = true;

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
      "io.github.kolunmi.Bazaar"               # Bazaar
      "com.bitwarden.desktop"                  # Bitwarden
      "com.fastmail.Fastmail"                  # Fastmail
      "org.signal.Signal"                      # Signal
      "com.github.wwmm.easyeffects"            # Easy Effect
      "org.freecad.FreeCAD"                    # FreeCAD
      "org.gimp.GIMP"                          # GIMP
      "gwenview"                               # GwenView
      "com.github.tchx84.Flatseal"             # Flatseal
      "org.kde.isoimagewriter"                 # ISO Image Writer
      "org.kde.kcalc"                          # KCalc
      "org.kde.kdenlive"                       # Kdenlive
      "org.kde.krita"                          # Krita
      "org.kicad.KiCad"                        # KiCAD
      "org.fkoehler.KTailctl"                  # KTailctl
      "org.libreoffice.LibreOffice"            # LibreOffice
      "com.nextcloud.desktopclient.nextcloud"  # Nextcloud Desktop Client
      "md.obsidian.Obsidian"                   # Obsidian
      "org.kde.okular"                         # Okular
      "io.github.alainm23.planify"             # Planify
      "com.vysp3r.ProtonPlus"                  # Proton+
      "io.github.tobagin.scramble"             # Scramble
      "com.spotify.Client"                     # Spotify
      "io.gitlab.adhami3310.Converter"         # Switcheroo Image Converter
      "com.mastermindzh.tidal-hifi"            # Tidal HiFi
      "org.videolan.VLC"                       # VLC
      "io.github.flattool.Warehouse"           # Warehouse
      "org.filezillaproject.Filezilla"         # Filezilla
      "com.dreamsourcelab.DSView"              # DSView
      "com.discordapp.Discord"                 # Discord
      "com.usebottles.bottles"                 # Bottles
      "org.kde.kdiff3"                         # KDiff3 KDE File Comparison Tool

    ];
  };

  ### SYSTEM PACKAGES ###
  environment.systemPackages = with pkgs; [
    (vscode-with-extensions.override {
      vscode = vscodium;
      vscodeExtensions = with vscode-extensions; [
        yzhang.markdown-all-in-one
        ana-mara4353.nix-ide
        jnoortheen.nix-ide
        docker.docker
      ];
    })
    brave-origin
    zed-editor
    kdePackages.kcharselect # Character map
    kdePackages.kclock # Clock app
    kdePackages.kcolorchooser # Color picker
    kdePackages.kolourpaint # Simple paint program
    kdePackages.ksystemlog # System log viewer
    kdePackages.partitionmanager # Disk and partition management
    hardinfo2 # System benchmarks and hardware info
    wayland-utils # Wayland diagnostic tools
    wl-clipboard # Wayland copy/paste support
    firefox
  ];

  ### BRAVE ORIGIN ###
  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
      "kgcjekpmcjjogibpjebkhaanilehneje" # KaraKeep
      # "cdglnehniifkbagbbombnjghhcihifij" # Kagi
    ];
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
    defaultSearchProviderSuggestURL= "https://kagisuggest.com/api/autosuggest?q={searchTerms}";
    extraOpts = {
      "WebAppInstallForceList" = [
        {
          "custom_name" = "Home Assistant";
          "create_desktop_shortcut" = false;
          "default_launch_container" = "window";
          "url" = "https://hass.31337.im";
        }
      ];
    };
  };

  ### ENABLE CUPS ###
  services.printing.enable = true;

  ### ENABLE PIPEWIRE ###
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  nixpkgs.config.pulseaudio = true;
  hardware.pulseaudio.extraConfig = "load-module module-combine-sink";
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
  };

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
