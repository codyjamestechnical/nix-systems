{ config, pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      acme.gid = 984;
      docker.gid = 131;
    };

    users.docker = {
      isNormalUser = false;
      isSystemUser = true;
      group = "docker";
      uid = 991;
      extraGroups = [
        "acme"
        "docker"
      ];
    };
  };

}
