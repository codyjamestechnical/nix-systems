{ config, pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      acme.gid = 984;
    };

    users.docker = {
      isNormalUser = false;
      isSystemUser = true;
      group = "docker";
      extraGroups = [
        "acme"
      ];
    };
  };

}
