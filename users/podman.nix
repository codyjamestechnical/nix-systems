{ config, pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
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
