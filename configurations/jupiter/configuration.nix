{inputs, outputs, lib, config, pkgs, ...}:
let 
  # network
  hostname = "jupiter";

  #firewall
  firewall-enable = true;

  # ssh
  banner = "Welcome to Jupiter server!";

  # tailscale 
  ts-auth-key = "48f925e5d61f884cabb05bea126da0340cbd3335870f68d5";
  ts-dns-name = "jupiter.server.cjtech.io";

  # nixos
  nixos-version = "23.11";

in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../modules/ssh.nix
    ../modules/users.cody.nix
    ../modules/nvidia.nix
    ../modules/tailscale.nix
    ../nix-containers/nextcloud.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Automate garbage collection
  nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
  };

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };

  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAtters (_: lib.isType "flake")) inputs);

  nix.nixPath = ["/etc/nix/path"];

  environment.etc = 
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  # boot
  
  # timezone
  time.timeZone = "America/New_York";

  # networking
  networking = {
    hostName = ${hostname};
    hostId = "8f150424";
    networkmanager.enable = false;
    dhcpcd.denyInterfaces = [ "macvtap0@*" ];

    # firewall
    firewall.enable = ${firewall-enable};

    macvlans = {
      mv-libvirtd= {
        interface = "enp1s0f1";
        mode = "bridge";
      };
    };
  
    interfaces = {
      mv-libvirtd = {
        ipv4.addresses = [ 
          {
            address = "10.0.30.50";
            prefixLength = 27;
          }
        ];
      };
    };
  };

  # ssh banner
  services.openssh.banner = ${banner};

  # tailscale
  services.cjt-tailscale = {
    enable = true;
    auth.key = ${ts-auth-key};
  };
  
  # acme
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "cody@31337.im";
  security.acme.certs."31337.im" = {
    domain = "*.31337.im";
    dnsProvider = "cloudflare";
    credentialsFile = "/var/lib/secrets/certs.secret";
    # We don't need to wait for propagation since this is a local DNS server
    dnsPropagationCheck = false;
    group = "acme";
  };

  # system version
  system.stateVersion = ${nixos-version};

  # nextcloud
  services.nextcloud-container = {
    enable = true;
    tailscale.authKey = ${ts-auth-key};
  };

  

}