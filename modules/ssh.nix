{inputs, outputs, lib, config, pkgs, ...}:
{
  service.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = false;
      PasswordAuthentication = false;
      UseDns = true;
    };
  };

  programs.mosh.enable = true;
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  environment.systemPackages = with pkgs; [
    tmux
    mosh
}