{ config, pkgs, ... }:
let
  cfg = {
    service_name = "arcane";
    network_name = "arcane-internal";
    base_dir = "/docker-data/arcane";
    secrets_dir = "/etc/nixos/secrets";
    caddyfile = pkgs.writeText "Caddyfile" ''
      (ssl) {
          tls /ssl/fullchain.pem /ssl/privkey.pem
      }
      arcane.31337.im, https://localhost {
        import ssl
        reverse_proxy arcane-server:3000
      }
    '';
    ociBin = "${config.virtualisation.oci-containers.backend}";
    # List of volumes to create if they don't exist
    create_volumes = [
      "${cfg.base_dir}/data:/app/data"
    ];
    # Extract host paths (the part before the first ':')
    hostPaths = map (v: builtins.head (lib.strings.splitString ":" v)) create_volumes;

    # Filter to absolute paths and ignore devices (like /dev/net/tun)
    hostDirs = builtins.filter (p: lib.hasPrefix "/" p && !(lib.hasPrefix "/dev/" p) && !(lib.hasPrefix "/var/" p)) hostPaths;

    # Generate the tmpfiles rules mapping
    volumeTmpfilesRules = map (dir: "d ${dir} 0750 ${ociBin} ${ociBin} -") hostDirs;
  };
in
{
  imports = [
    (import ./caddy.nix { inherit cfg; })
    (import ./tailscale.nix { inherit cfg; })
    (import ./docker-network.nix { inherit cfg; })
  ];

  # Dynamically apply the generated tmpfiles rules
  systemd.tmpfiles.rules = volumeTmpfilesRules;

  # Containers
  virtualisation.oci-containers.containers = {

    ### ARCANE ###
    "${cfg.service_name}-server" = {
      image = "ghcr.io/getarcaneapp/manager:latest";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${cfg.base_dir}/data:/app/data"
      ];
      extraOptions = [
        "--network-alias=${cfg.service_name}-server"
        "--network=${cfg.network_name}"
      ];
    };

  };

}
