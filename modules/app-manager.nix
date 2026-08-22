{ config, lib, inputs, pkgs, ... }:
let
  cfg = config.modules.app-manager;
in
{
  options.modules.app-manager = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Install AppManager, a GTK AppImage installer and manager.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.app-manager.packages.${pkgs.system}.default
    ];
  };
}
