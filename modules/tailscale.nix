{ lib, pkgs, config, ... }:
with lib;                      
let
  cfg = config.services.cjt-tailscale;
in {
  # Declare what settings a user of this "hello.nix" module CAN SET.
  options.services.cjt-tailscale = {
    enable = mkEnableOption "CJT Tailscale";

    userspace.enable = mkOption {
      type = types.str;
      default = "false";
    };

    userspace.state_dir = mkOption {
      type = types.str;
      default = "/var/lib/tailscale/talescaled-${cfg.hostname}";
    };

    auth.key = mkOption {
      type = types.str;
      default = "";
    };

    auth.url = mkOption {
      type = types.str;
      default = "https://tail.cjtech.io:443";
    };

    hostname = mkOption {
      type = types.str;
      default = "";
    };

    advertise_tags = mkOption {
      type = types.str;
      default = "tag:server";
    };

    acceptDNS = mkOption {
      type = types.str;
      default = "true";
    };

    enableSSH = mkOption {
      type = types.str;
      default = "true";
    };
  };

  # Define what other settings, services and resources should be active IF
  # a user of this "hello.nix" module ENABLED this module 
  # by setting "services.hello.enable = true;".
  config = mkIf cfg.enable {
    # make the tailscale command usable to users
    environment.systemPackages = [ pkgs.tailscale ];

    # enable the tailscale service
    services.tailscale.enable = true;

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        userspace = "${cfg.userspace.enable}"

        if [$userspace = "true"]; then
          sudo mkdir -p ${cfg.userspace.state_dir}
          sudo env STATE_DIRECTORY=${cfg.userspace.state_dir} tailscaled --statedir=${cfg.userspace.state_dir} --socket=${cfg.userspace.state_dir}/tailscaled.sock --port=0 --tun=user
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up --ssh -authkey ${cfg.auth.key} -login-server ${cfg.auth.url} --hostname ${cfg.hostname} --advertise-tags ${cfg.advertise_tags} --accept-dns=${cfg.acceptDNS} --ssh ${cfg.enableSSH}
      '';
  };

      
  };
}