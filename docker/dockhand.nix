{ config, pkgs, ... }:
let


  cfg = rec {
    service_name = "dockhand";
    network_name = "dockhand-internal";
    base_dir = "/docker-data/dockhand";
    secrets_dir = "/etc/nixos/secrets";
    caddyfile = caddyfileText = pkgs.writeText "Caddyfile" ''
      (ssl) {
          tls /ssl/fullchain.pem /ssl/privkey.pem
      }
      dockhand.31337.im, https://localhost {
        import ssl
        reverse_proxy dockhand-server:3000
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

    ### DOCKHAND ###
    "${cfg.service_name}-server" = {
      image = "fnsys/dockhand:latest";
      user = "0:0";
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
