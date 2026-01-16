{
  inputs,
  config,
  pkgs,
  ...
}:
{

  users = {
    defaultUserShell = pkgs.zsh;
    users.cody = {
      isNormalUser = true;
      description = "Cody";
      hashedPasswordFile = /etc/nixos/secrets/cody_password;
      extraGroups = [
        "networkmanager"
        "wheel"
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
      ];
      packages = with pkgs; [
      ];
    };
  };

}
