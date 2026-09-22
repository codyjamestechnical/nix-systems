{ config, pkgs, ... }:
{
  imports = [
    ../users/docker.nix # Import docker user
  ];
  
  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Creates a symlink from docker to podman
    virtualisation.podman.autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
  };

  # add podman and podman-compose
  environment.systemPackages = with pkgs; [ 
    podman-compose
    dive
    podman-tui
  ];

  # Allow non-root containers to access lower port numbers
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # Automatically start containers on boot
  systemd.services.podman-autostart = {
    enable = true;
    after = [ "podman.service" ];
    wantedBy = [ "multi-user.target" ];
    description = "Automatically start containers with --restart=always tag";
    serviceConfig = {
      Type = "idle";
      User = "docker";
      ExecStartPre = ''${pkgs.coreutils}/bin/sleep 1'';
      ExecStart = ''/run/current-system/sw/bin/podman start --all --filter restart-policy=always'';
    };
  };
  

}