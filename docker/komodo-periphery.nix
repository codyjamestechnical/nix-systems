{ config, pkgs, ... }:
let
  cfg = {
    service_name = "komodo-periphery";
    network_name = "komodo-periphery-internal";
    base_dir = "/docker-data/komodo-periphery";
    secrets_dir = "/etc/nixos/secrets";
  };
in
{
  ### OCI CONTAINERS ###
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {

    ### KOMODO PERIPHERY ###
    "${cfg.service_name}" = {
      image = "ghcr.io/moghtech/komodo-periphery:2";
      ports = [ "0.0.0.0:8120:8120" ];
      log-driver = "journald";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "/proc:/proc"

        "${cfg.base_dir}/keys:/config/keys"
        "${cfg.base_dir}/config:${cfg.base_dir}/config" #this must be the same on contianer & host or docekr will get confused
      ];
      environmentFiles = [
        "/docker-data/.env"
        "${cfg.base_dir}/.env"
      ];
      labels = {
        "komodo.skip" = "";
      };
    };

  };
}

### PERIPHERY ENV TEMPLATE ###
# place this file in ${cfg.base_dir}/.env
#
# ## The address of Komodo Core to connect to.
# PERIPHERY_CORE_ADDRESS: komodo.31337.im
#
# ## The name of the Komodo Server to connect as.
# ## Must match existing server.
# PERIPHERY_CONNECT_AS: <server-name>
#
# ## Optional. Create a Server Onboarding Key in the Komodo UI.
# ## This allows Periphery to create a new Server in the UI with the above name,
# ## and can be ommitted once the Server exists in Komodo.
# PERIPHERY_ONBOARDING_KEY: <your-onboarding-key>
#
# ## List of accepted Core public keys.
# ## File will be auto written if doesn't exist to match first Core it connects to.
# PERIPHERY_CORE_PUBLIC_KEYS: file:/config/keys/core.pub
#
# ## Specify the root directory used by Periphery agent.
# ## All your compose files and repos need to be inside this directory
# ## for Periphery to interact with them.
# PERIPHERY_ROOT_DIRECTORY: ${PERIPHERY_ROOT_DIRECTORY:-/docker-data/komodo-periphery/config}
#
# ## Specify whether to disable the terminals feature
# ## and disallow remote shell access (inside the Periphery container).
# PERIPHERY_DISABLE_TERMINALS: false
#
# ## Specify whether to disable the container exec feature
# ## and disallow remote container shell access.
# PERIPHERY_DISABLE_CONTAINER_EXEC: false
#
# ## If the disk size is overreporting, can use one of these to
# ## whitelist / blacklist the disks to filter them, whichever is easier.
# ## Accepts comma separated list of paths.
# ## Usually whitelisting just /etc/hostname gives correct size for single root disk.
# PERIPHERY_INCLUDE_DISK_MOUNTS: /etc/hostname
#
# ## Uncomment to exclude disk mounts (e.g. /snap, /etc/repos)
# # PERIPHERY_EXCLUDE_DISK_MOUNTS: /snap,/etc/repos
