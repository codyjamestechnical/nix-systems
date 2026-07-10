# Reusable Caddy module.
#
# Defines the caddy reverse-proxy container. It is a curried module: it takes
# `{ cfg }` and returns a NixOS module, so add it to the module's `imports`
# list (NOT the `containers` attrset):
#
#   imports = [ (import ./caddy.nix { inherit cfg; }) ];
#
# Expected `cfg` fields:
#   service_name - prefix used for the container name (required)
#   base_dir     - host path holding caddy data/config (required)
#   caddyfile    - store path (e.g. pkgs.writeText ...) mounted as Caddyfile (required)
#   network_name - docker network to attach to (required)
#
# Optional `cfg` fields (with defaults):
#   caddy_image         - container image            (default "caddy:latest")
#   caddy_network_alias - --network-alias value      (default "caddy")
#   caddy_ssl_cert      - host path to fullchain.pem (default /var/lib/acme/31337.im/fullchain.pem)
#   caddy_ssl_key       - host path to privkey       (default /var/lib/acme/31337.im/key.pem)
#   caddy_ports         - list of published ports    (default [])
#   caddy_env_files     - list of env files          (default the two shown below)
#   caddy_extra_labels  - extra container labels      (default {})
#   caddy_oci_backend   - OCI backend to use (default "docker")

{ cfg }:

let
  image = cfg.caddy_image or "caddy:latest";
  networkAlias = cfg.caddy_network_alias or "caddy";
  sslCert = cfg.caddy_ssl_cert or "/var/lib/acme/31337.im/fullchain.pem";
  sslKey = cfg.caddy_ssl_key or "/var/lib/acme/31337.im/key.pem";
  ports = cfg.caddy_ports or [ ];
  envFiles = cfg.caddy_env_files or [];
  extraLabels = cfg.caddy_extra_labels or { };
  ociBackend = cfg.caddy_oci_backend or "docker";
in
{
  virtualisation.oci-containers.backend = ociBackend;
  virtualisation.oci-containers.containers."${cfg.service_name}-caddy" = {
    inherit image ports;

    labels = {
      "komodo.skip" = "";
    } // extraLabels;

    environmentFiles = envFiles;

    volumes = [
      "${cfg.base_dir}/caddy/data:/data:rw"
      "${cfg.base_dir}/caddy/config:/config:rw"
      "${cfg.caddyfile}:/etc/caddy/Caddyfile:ro"
      "${sslCert}:/ssl/fullchain.pem:ro"
      "${sslKey}:/ssl/privkey.pem:ro"
    ];

    log-driver = "journald";

    extraOptions = [
      "--cap-add=NET_ADMIN"
      "--network-alias=${networkAlias}"
      "--network=${cfg.network_name}"
    ];
  };
}
