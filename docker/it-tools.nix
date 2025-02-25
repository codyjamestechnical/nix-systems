{inputs, outputs, lib, config, pkgs, ...}:
with lib;
let
  cfg = config.services.it-tools;
in
{
  options = {
    services.it-tools = {
      tailscale = {
        enable = mkEnableOption "Enable tailscale";
        authkey = mkOption {
          type = types.str;
          description = "Tailscale authkey";
        };
      };
    };
  };
  virtualisation.oci-containers.containers = {
    tailscale-it-tools = {
      image = "tailscale/tailscale:latest";
      extraOptions = [
        "--hostname=it-tools"
        "--network=ts-it-tools"
      ];
      environment = {
        TS_AUTHKEY = config.tailscale.authkey;
        TS_STATE_DIR="/var/lib/tailscale";
        TS_EXTRA_ARGS="--login-server https://tail.cjtech.io:443 --cap-add NET_RAW --cap-add NET_ADMIN";

      };
      volumes = [
        "/dev/net/tun:/dev/net/tun"
        "./tailscale_var_lib:/var/lib"
      ];
    };

    nginx = {
      image = "nginxproxy/nginx-proxy:latest";
      extraOptions = [
        "--hostname=nginx"
        "--network=ts-nginx"
      ];
      volumes = [
        "/var/run/docker.sock:/tmp/docker.sock:ro"
        "/var/lib/ssl/31337.im:/etc/nginx/certs"
      ];
      ports = [
        "80:80"
        "443:443"
      ];
    };
    it-tools = {
      image = "corentinth/it-tools:latest";
      extraOptions = [
        "--hostname=it-tools"
        "--network=ts-it-tools"
      ];
    }
  };
}