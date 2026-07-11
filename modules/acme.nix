{config, pkgs, lib, ...}:
let
  cfg = config.modules.acme;
in
{
  options.modules.acme = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the acme module.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "cody@31337.im";
      description = "Email address for ACME.";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "31337.im";
      description = "Domain for ACME.";
    };

    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "cloudflare";
      description = "DNS provider for ACME.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/secrets/${cfg.dnsProvider}-token";
      description = "Environment file for ACME.";
    };

    dnsPropagationCheck = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "DNS propagation check for ACME.";
    };

  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.email;
      defaults = {
        # Restart all containers that use the caddy image after renewal
        # postRun = "docker ps -a --filter 'ancestor=caddy' --format '{{.ID}}' | xargs docker restart";
        postRun = "openssl pkcs12 -export -out /var/lib/acme/${cfg.domain}/${cfg.domain}.pfx -inkey /var/lib/acme/${cfg.domain}/key.pem -in /var/lib/acme/${cfg.domain}/fullchain.pem -passout pass: && chmod 640 /var/lib/acme/${cfg.domain}/${cfg.domain}.pfx && chown acme:acme /var/lib/acme/${cfg.domain}/${cfg.domain}.pfx";
        renewInterval = "monthly";
      };
      certs."${cfg.domain}" = {
        domain = "*.${cfg.domain}";
        dnsProvider = "${cfg.dnsProvider}";
        environmentFile = "${cfg.environmentFile}";
        dnsPropagationCheck = cfg.dnsPropagationCheck;
      };
    };
  };
}
