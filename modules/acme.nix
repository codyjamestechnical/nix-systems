{config, pkgs, ...}:
{
    # Now we can configure ACME
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "cody@31337.im";
  security.acme.defaults = {
    # Restart all containers that use the caddy image after renewal
    # postRun = "docker ps -a --filter 'ancestor=caddy' --format '{{.ID}}' | xargs docker restart";
    renewInterval = "monthly";
  };
  security.acme.certs."31337.im" = {
    domain = "*.31337.im";
    dnsProvider = "cloudflare";
    environmentFile = "/var/secrets/cloudflare-token";
    dnsPropagationCheck = true;
  };
}