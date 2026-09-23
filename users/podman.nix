{ config, pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      acme.gid = 1000;
      podman.gid = 1000;
    };

    users.podman = {
      isNormalUser = false;
      isSystemUser = true;
      group = "podman";
      uid = 1000;
      extraGroups = [
        "acme"
        "podman"
      ];
    };
  };

}
