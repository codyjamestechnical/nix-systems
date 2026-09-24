{ config, lib, pkgs, ... }:
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
        reverse_proxy arcane-server:3552
      }
    '';
  };

  ociBin = "${config.virtualisation.oci-containers.backend}";
  dockerSocket = if ociBin == "docker" then "/var/run/docker.sock" else "/run/user/1001/podman/podman.sock";
  # List of volumes to create if they don't exist
  create_volumes = [
    "${cfg.base_dir}/data"
  ];
  # Generate the tmpfiles rules mapping
  volumeTmpfilesRules = map (dir: "d ${dir} 0770 ${ociBin} ${ociBin} -") create_volumes;
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
      environmentFiles = [
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${dockerSocket}:/var/run/docker.sock"
        "${cfg.base_dir}/data:/app/data"
      ];
      extraOptions = [
        "--network-alias=${cfg.service_name}-server"
        "--network=${cfg.network_name}"
      ];
    };

  };

}
