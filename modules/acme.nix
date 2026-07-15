{config, pkgs, lib, ...}:
# This module creates ACME certificates for the domains listed in the domains portion of the configuration using a single config for the dns provider for all domains.
# It simplifies the process of creating certificates for multiple domains by using a single dns provider for all of them.
# the module does require that the dns provider auth is set via the environmentFile option in /etc/nixos/secrets/[[dns provider name here]]-token
#
# example
# modules.acme = {
#   domains = [ "example.com" "example2.com" ]; # the module will create a wildcard certificate for example.com and example2.com
# };
#

let
  cfg = config.modules.acme;

  mkCert = domain: {
    name = domain;
    value = {
      domain = "*.${domain}";
      dnsProvider = cfg.dnsProvider;
      environmentFile = cfg.environmentFile;
      dnsPropagationCheck = cfg.dnsPropagationCheck;
      # Create a PKCS12 certificate from the fullchain and key
      postRun = ''
        openssl pkcs12 -export \
          -out /var/lib/acme/${domain}/${domain}.pfx \
          -inkey /var/lib/acme/${domain}/key.pem \
          -in /var/lib/acme/${domain}/fullchain.pem \
          -passout pass: && \
        chmod 640 /var/lib/acme/${domain}/${domain}.pfx && \
        chown acme:acme /var/lib/acme/${domain}/${domain}.pfx
      '';
    };
  };
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

    domains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "31337.im" ];
      description = "Domains to issue wildcard certificates for.";
      example = [ "31337.im" "example.com" ];
    };

    dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "cloudflare";
      description = "DNS provider for ACME (shared across all domains).";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/secrets/${cfg.dnsProvider}-token";
      description = "Environment file for ACME (shared across all domains).";
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
      defaults = {
        email = cfg.email;
        renewInterval = "monthly";
      };
      certs = lib.listToAttrs (map mkCert cfg.domains);
    };
  };
}
