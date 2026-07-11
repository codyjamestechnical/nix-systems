# Reusable Tailscale module.
#
# Defines the tailscale sidecar container AND the one-shot systemd service
# that strips TS_AUTHKEY from the service's .env shortly after the container
# authenticates (after the first successful auth the key is no longer needed,
# since state is persisted).
#
# Because it registers a top-level systemd service, this must be added to the
# module's `imports` list, NOT to the `containers` attrset. It is a curried
# module: it takes `{ cfg }` and returns a NixOS module, so `pkgs`/`lib` are
# supplied automatically by the module system.
#
#   imports = [ (import ./tailscale.nix { inherit cfg; }) ];
#
# Expected `cfg` fields:
#   service_name - prefix used for the container / service name / hostname (required)
#   base_dir     - host path holding tailscale state and the .env file (required)
#
# Optional `cfg` fields (with defaults):
#   tailscale_image                 - container image      (default "tailscale/tailscale:latest")
#   tailscale_depends_on            - dependsOn list        (default [ "<svc>-server" "<svc>-caddy" ])
#   tailscale_env_files             - list of env files     (default the two shown below)
#   tailscale_network               - network mode          (default "container:<svc>-caddy")
#   tailscale_hostname              - TS_HOSTNAME           (default cfg.service_name)
#   tailscale_state_host_path       - host path for state   (default "<base_dir>/data/tailscale")
#   tailscale_volumes               - full volumes override  (default tun + state mount)
#   tailscale_login_server          - --login-server URL     (default "https://headscale.cjtech.io")
#   tailscale_tags                  - tags for --advertise-tags (default "")
#   tailscale_accept_dns            - TS_ACCEPT_DNS          (default "false")
#   tailscale_userspace             - TS_USERSPACE           (default "false")
#   tailscale_extra_args            - full TS_EXTRA_ARGS override (default advertise-tags + login-server)
#   tailscale_extra_tailscaled_args - full TS_TAILSCALED_EXTRA_ARGS override (default "")
#   tailscale_extra_labels          - extra container labels (default {})
#   tailscale_authkey_cleanup       - enable the authkey cleanup service (default true)
#   authkey_cleanup_delay           - seconds to wait before removing the key (default 60)
#   tailscale_oci_backend           - OCI backend to use (default "docker")

{ cfg }:

{ pkgs, lib, ... }:

let
  image = cfg.tailscale_image or "tailscale/tailscale:latest";
  dependsOn = cfg.tailscale_depends_on or [
    "${cfg.service_name}-caddy"
  ];
  envFiles = cfg.tailscale_env_files or [
    "/docker-data/.env"
    "${cfg.base_dir}/.env"
  ];
  network = cfg.tailscale_network or "container:${cfg.service_name}-caddy";
  hostname = cfg.tailscale_hostname or cfg.service_name;
  stateHostPath = cfg.tailscale_state_host_path or "${cfg.base_dir}/tailscale";
  volumes = cfg.tailscale_volumes or [
    "/dev/net/tun:/dev/net/tun"
    "${stateHostPath}:/var/lib/tailscale:rw"
  ];
  tags = cfg.tailscale_tags or "";
  loginServer = cfg.tailscale_login_server or "https://headscale.cjtech.io";
  acceptDns = cfg.tailscale_accept_dns or "false";
  userspace = cfg.tailscale_userspace or "false";
  extraArgs = cfg.tailscale_extra_args or "--advertise-tags=${tags} --login-server=${loginServer}";
  extraTailscaledArgs = cfg.tailscale_extra_tailscaled_args or "";
  extraLabels = cfg.tailscale_extra_labels or { };

  cleanupEnabled = cfg.tailscale_authkey_cleanup or true;
  cleanupDelay = cfg.authkey_cleanup_delay or 60;
  ociBackend = cfg.tailscale_oci_backend or "docker";
in
{
  virtualisation.oci-containers.backend = ociBackend;
  virtualisation.oci-containers.containers."${cfg.service_name}-tailscale" = {
    inherit image dependsOn volumes;

    labels = {
      "komodo.skip" = "";
    } // extraLabels;

    environmentFiles = envFiles;

    log-driver = "journald";

    extraOptions = [
      "--network=${network}"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
    ];

    environment = {
      TS_HOSTNAME = hostname;
      TS_STATE_DIR = "/var/lib/tailscale";
      TS_ACCEPT_DNS = acceptDns;
      TS_USERSPACE = userspace;
      TS_EXTRA_ARGS = extraArgs;
      TS_TAILSCALED_EXTRA_ARGS = extraTailscaledArgs;
    };
  };

  ### FIREWALL ###
  networking.firewall = {
    # open UDP port for tailscale
    allowedUDPPorts = [ 41641 ];
  };

  systemd.services = lib.optionalAttrs cleanupEnabled {
    "${cfg.service_name}-tailscale-authkey-cleanup" = {
      description = "Remove TS_AUTHKEY from ${cfg.service_name} .env after tailscale authenticates";
      after = [ "docker-${cfg.service_name}-tailscale.service" ];
      wantedBy = [ "docker-${cfg.service_name}-tailscale.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "cleanup-ts-authkey-${cfg.service_name}" ''
          sleep ${toString cleanupDelay}
          ${pkgs.gnused}/bin/sed -i '/^TS_AUTHKEY/d' "${cfg.base_dir}/.env"
        '';
      };
    };
  };
}
