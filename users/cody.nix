{
  inputs,
  config,
  pkgs,
  ...
}:
{

  users = {
    defaultUserShell = pkgs.zsh;
    # $ISBN&PN&FIRSTLETTER$
    groups = {
      cody.gid = 1001;
    };

    users.cody = {
      isNormalUser = true;
      description = "Cody";
      uid = 1001;
      hashedPasswordFile = "/etc/nixos/secrets/cody_password";
      extraGroups = [
        "networkmanager"
        "wheel"
        "podman"
        "docker"
        "libvirtd"
        "acme"
      ];
      shell = pkgs.zsh;
      # openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
      # openssh.authorizedKeys.keyFiles = [
      #     (builtins.fetchurl { url = "https://github.com/codyjamestechnical.keys?1";})
      # ];
      # openssh.authorizedKeys.keys = builtins.readFile (
      #     builtins.fetchurl {
      #         url=https://github.com/codyjamestechnical.keys ; sha256 = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
      #         }
      #     );
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIEB06+mXFpYiRLegmXjiZzPuF1rTs+ySVCn5mJ0hpZ cody@cjtech.io"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7GF3+KjXW+H9A3ojMTn4lpEp0WE+2P/EE5aWGwmOk7 cody@cjtech.io"
      ];
      packages = with pkgs; [

      ];
    };
  };

  ### ZSH SHELL ALIAS (cody only) ###
  programs.zsh.interactiveShellInit = ''
    if [ "$USER" = "cody" ]; then
      # alias the podman command to use the podman user
      alias podman="sudo -u podman podman"
      # Run podman as the podman user. Use a function instead of an
      # alias so we can cd to / first: rootless podman re-execs and
      # chdirs into the current working directory, which fails if we
      # are inside /home/cody (not accessible to the podman user).
      podman() {
        ( cd / && exec sudo -H -u podman podman "$@" )
      }
    fi
  '';

}
