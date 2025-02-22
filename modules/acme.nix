{config, pkgs, ...}:
{
    # Now we can configure ACME
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "cody@31337.im";
  security.acme.certs."31337.im" = {
    domain = "*.31337.im";
    dnsProvider = "cloudflare";
    environmentFile = "/var/secrets/cloudflare-token";
    dnsPropagationCheck = true;
    postRun = "docker restart $(docker ps -q)";
  };
}