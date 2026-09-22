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
  };
in
{
  imports = [
    (import ./caddy.nix { inherit cfg; })
    (import ./tailscale.nix { inherit cfg; })
    (import ./docker-network.nix { inherit cfg; })
  ];

  # Containers
  virtualisation.oci-containers.backend = "docker";
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