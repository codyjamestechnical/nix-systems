{ pkgs, lib, ... }:
let
  cfg = {
    service_name = "komodo";
    network_name = "komodo-internal";
    base_dir = "/docker-data/komodo";
    secrets_dir = "/etc/nixos/secrets";

    ## override tailscale config to attach it to the komodo-core instead of caddy
    tailscale_depends_on = [
      "${cfg.service_name}-core"
    ];
    tailscale_network = "container:${cfg.service_name}-core";
    # this is to help this container get a direct connection from tailscale
    # clients since this is a very important container
    tailscale_extra_tailscaled_args = "--port=41642";
  };
in
{
  # Import tailscale and docker-network modules
  imports = [
    (import ./tailscale.nix { inherit cfg; })
    (import ./docker-network.nix { inherit cfg; })
  ];

  ### FIREWALL ###
  networking.firewall = {
    # open UDP port for tailscale since we changed the port
    # the default port is 41641, but we changed it to 41642 in tailscale_extra_tailscaled_args
    allowedUDPPorts = [ 41642 ];
  };

  ### OCI CONTAINERS ###
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### KOMODO PERIPHERY ###
    "${cfg.service_name}-periphery" = {
      image = "ghcr.io/moghtech/komodo-periphery:2";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "${cfg.secrets_dir}/komodo-periphery/keys:/config/keys"
        # "/etc/komodo/ssl:/etc/komodo/ssl"
        # "/etc/komodo/repos:/etc/komodo/repos"
        # "/etc/komodo/stacks:/etc/komodo/stacks"
        "${cfg.secrets_dir}/komodo-passkey:/var/secrets/passkey:ro"

      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=periphery"
        "--network=${cfg.network_name}"
      ];
    };

    ### KOMODO CORE ###
    "${cfg.service_name}-core" = {
      image = "ghcr.io/moghtech/komodo-core:2";
      ports = [ "41642:41642" ];
      labels = {
        "komodo.skip" = "";
        "homepage.group" = "Infrastructure & Monitoring";
        "homepage.name" = "Komodo";
        "homepage.icon" = "sh-komodo.svg";
        "homepage.href" = "https://komodo.31337.im";
        "homepage.description" = "Docker management & monitoring";
        "homepage.siteMonitor" = "https://komodo.31337.im";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      dependsOn = [
        "${cfg.service_name}-mongo"
      ];
      volumes = [
        "${cfg.base_dir}/keys:/config/keys"
        "/var/lib/acme/31337.im/fullchain.pem:/config/ssl/cert.pem:ro"
        "/var/lib/acme/31337.im/key.pem:/config/ssl/key.pem:ro"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=komodo-core"
        "--network=${cfg.network_name}"
        # "--network=name=ipvlan6,ip6=2a01:4ff:f0:f9f1:1::2"
      ];
    };

    ### MONGODB ###
    "${cfg.service_name}-mongo" = {
      image = "mongo";
      labels = {
        "komodo.skip" = "";
      };
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      volumes = [
        "${cfg.base_dir}/mongodb/config:/data/configdb:rw"
        "${cfg.base_dir}/mongodb/data:/data/db:rw"
      ];
      cmd = [
        "--quiet"
        "--wiredTigerCacheSizeGB"
        "0.25"
      ];
      log-driver = "local";
      extraOptions = [
        "--network-alias=mongo"
        "--network=${cfg.network_name}"
      ];
    };
  };

  # systemd.services.docker-ipvlan-net = {
  #     description = "Create IPv6-only Docker IPvlan network";
  #     after = [ "docker.service" ];
  #     requires = [ "docker.service" ];
  #     wantedBy = [ "multi-user.target" ];
  #     before = [ "docker-tailscale.service" ];
  #     serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
  #     path = [ pkgs.docker ];
  #     script = ''
  #       if ! docker network inspect ipvlan6 >/dev/null 2>&1; then
  #         docker network create \
  #           --driver ipvlan \
  #           --opt ipvlan_mode=l3 \
  #           --ipv6 \
  #           --subnet "2a01:4ff:f0:f9f1:1::/80" \
  #           --opt parent=eth0 \
  #           ipvlan6
  #       fi
  #     '';
  #   };

}


### KOMODO CORE & PERIPHERY ENV TEMPLATE ###
# # place this file in ${cfg.base_dir}/.env
#
# ## Tailscale auth key for setup. This will be auto deleted after the first run.
# TAILSCALE_AUTHKEY=
#
# ## Configure a secure passkey to authenticate between Core / Periphery.
# KOMODO_PASSKEY=
#
# #=-------------------------=#
# #= Komodo Core Environment =#
# #=-------------------------=#
#
# ## Full variable list + descriptions are available here:
# ## https://github.com/mbecker20/komodo/blob/main/config/core.config.toml
#
# ## Note. Secret variables also support `${VARIABLE}_FILE` syntax to pass docker compose secrets.
# ## Docs: https://docs.docker.com/compose/how-tos/use-secrets/#examples
#
# ## Used for Oauth / Webhook url suggestion / Caddy reverse proxy.
# KOMODO_HOST=https://komodo.31337.im
# KOMODO_PORT=443
#
# ## Displayed in the browser tab.
# KOMODO_TITLE=CJT Komodo
#
# ## Create a server matching this address as the "first server".
# ## Use `https://host.docker.internal:8120` when using systemd-managed Periphery.
# KOMODO_FIRST_SERVER=https://periphery:8120
#
# ## Make all buttons just double-click, rather than the full confirmation dialog.
# KOMODO_DISABLE_CONFIRM_DIALOG=true
#
# ## Rate Komodo polls your servers for
# ## status / container status / system stats / alerting.
# ## Options: 1-sec, 5-sec, 15-sec, 1-min, 5-min.
# ## Default: 15-sec
# KOMODO_MONITORING_INTERVAL=1-min
# ## Rate Komodo polls Resources for updates,
# ## like outdated commit hash.
# ## Options: 1-min, 5-min, 15-min, 30-min, 1-hr.
# ## Default: 5-min
# KOMODO_RESOURCE_POLL_INTERVAL=5-min
#
# ## Used to auth incoming webhooks. Alt: KOMODO_WEBHOOK_SECRET_FILE
# KOMODO_WEBHOOK_SECRET= [[KOMODO WEBHOOK SECRET]]
# ## Used to generate jwt. Alt: KOMODO_JWT_SECRET_FILE
# KOMODO_JWT_SECRET= [[KOMODO JWT SECRET]]
#
# ## Enable login with username + password.
# KOMODO_LOCAL_AUTH=true
# ## Disable new user signups.
# KOMODO_DISABLE_USER_REGISTRATION=false
# ## All new logins are auto enabled
# KOMODO_ENABLE_NEW_USERS=false
# ## Disable non-admins from creating new resources.
# KOMODO_DISABLE_NON_ADMIN_CREATE=false
# ## Allows all users to have Read level access to all resources.
# KOMODO_TRANSPARENT_MODE=false
#
# ## Time to live for jwt tokens.
# ## Options: 1-hr, 12-hr, 1-day, 3-day, 1-wk, 2-wk
# KOMODO_JWT_TTL=2-wk
#
# ## Github Oauth
# KOMODO_GITHUB_OAUTH_ENABLED=false
# # KOMODO_GITHUB_OAUTH_ID= # Alt: KOMODO_GITHUB_OAUTH_ID_FILE
# # KOMODO_GITHUB_OAUTH_SECRET= # Alt: KOMODO_GITHUB_OAUTH_SECRET_FILE
#
# ## Google Oauth
# KOMODO_GOOGLE_OAUTH_ENABLED=false
# # KOMODO_GOOGLE_OAUTH_ID= # Alt: KOMODO_GOOGLE_OAUTH_ID_FILE
# # KOMODO_GOOGLE_OAUTH_SECRET= # Alt: KOMODO_GOOGLE_OAUTH_SECRET_FILE
#
# ## Generic OIDC
# KOMODO_OIDC_ENABLED=true
# KOMODO_OIDC_PROVIDER=https://auth.31337.im
# KOMODO_OIDC_CLIENT_ID=
# KOMODO_OIDC_CLIENT_SECRET=
# KOMODO_OIDC_USE_FULL_EMAIL=true
#
# ## Aws - Used to launch Builder instances and ServerTemplate instances.
# KOMODO_AWS_ACCESS_KEY_ID= # Alt: KOMODO_AWS_ACCESS_KEY_ID_FILE
# KOMODO_AWS_SECRET_ACCESS_KEY= # Alt: KOMODO_AWS_SECRET_ACCESS_KEY_FILE
#
# ## Hetzner - Used to launch ServerTemplate instances
# ## Hetzner Builder not supported due to Hetzner pay-by-the-hour pricing model
# KOMODO_HETZNER_TOKEN= # Alt: KOMODO_HETZNER_TOKEN_FILE
#
# KOMODO_SSL_ENABLED=true
#
# ## Database Connection Info
# KOMODO_DATABASE_ADDRESS=mongo:27017
# KOMODO_DATABASE_USERNAME=admin
# KOMODO_DATABASE_PASSWORD=admin
#
# Mongo InitDB credentials
# MONGO_INITDB_ROOT_USERNAME=admin
# MONGO_INITDB_ROOT_PASSWORD=admin
#
# #=------------------------------=#
# #= Komodo Periphery Environment =#
# #=------------------------------=#
#
# ## Full variable list + descriptions are available here:
# ## https://github.com/mbecker20/komodo/blob/main/config/periphery.config.toml
#
# PERIPHERY_SSL_ENABLED=true
# PERIPHERY_INCLUDE_DISK_MOUNTS=/etc/hostname
# PERIPHERY_PASSKEYS_FILE=/var/secrets/passkey
