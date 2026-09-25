{ config, pkgs, ... }:
{
  users = {
    defaultUserShell = pkgs.zsh;
    groups = {
      podman.gid = 1000;
    };

    users.podman = {
      isNormalUser = true;
      # isSystemUser = true;
      linger = true;
      group = "podman";
      uid = 1000;
      extraGroups = [
        "acme"
      ];
    };
  };

  # Enable the rootless podman socket for user sessions (equivalent to
  # `systemctl --user enable podman.socket`). Combined with
  # users.users.podman.linger = true, this starts at boot for the podman user.
  systemd.user.sockets.podman.wantedBy = [ "sockets.target" ];
}
