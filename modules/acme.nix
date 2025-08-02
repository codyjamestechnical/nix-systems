{config, pkgs, ...}:
{
    # Now we can configure ACME
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "cody@31337.im";
  security.acme.defaults = {
    # Restart all containers that use the caddy image after renewal
    # postRun = "docker ps -a --filter 'ancestor=caddy' --format '{{.ID}}' | xargs docker restart";
    postRun = "openssl pkcs12 -export -out /var/lib/acme/31337.im/31337.im.pfx -inkey /var/lib/acme/31337.im/key.pem -in /var/lib/acme/31337.im/fullchain.pem -passout pass: && chmod 640 /var/lib/acme/31337.im/31337.im.pfx && chown acme:acme /var/lib/acme/31337.im/31337.im.pfx";
    renewInterval = "monthly";
  };
  security.acme.certs."31337.im" = {
    domain = "*.31337.im";
    dnsProvider = "cloudflare";
    environmentFile = "/var/secrets/cloudflare-token";
    dnsPropagationCheck = true;
  };
}