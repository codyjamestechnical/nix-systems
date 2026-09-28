{ inputs, config, pkgs, ... }:
{
  imports = [
      ./hardware-configuration.nix
  ];

  ### NETWORKING ###
  networking = {
      hostName = "core-infra";
  };

  ### INTEL FWUPD MODS ###
  services.fwupd.extraRemotes = [ "lvfs-testing" ];
  services.fwupd.uefiCapsuleSettings.DisableCapsuleUpdateOnDisk = true;

  ### ENABLE NIXOS POWER MANAGEMENT ###
  powerManagement.enable = true;

  ### ENABLE POWERTOP ###
  powerManagement.powertop.enable = true;

  ### ENABLE AUTO CPUFREQ ###
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "auto";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };

  ### ENABLE THERMALD FOR INTEL CPUs ###
  services.thermald.enable = true;

  ### ENABLE STEAM ###
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;  # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports for Source Dedicated Server hosting
  };

  ### ENABLE TLP ###
  services.tlp = {
    enable = false;

    # settings = {
    #   CPU_SCALING_GOVERNOR_ON_AC = "performance";
    #   CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

    #   CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    #   CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

    #   CPU_MIN_PERF_ON_AC = 0;
    #   CPU_MAX_PERF_ON_AC = 100;
    #   CPU_MIN_PERF_ON_BAT = 0;
    #   CPU_MAX_PERF_ON_BAT = 20;

    #   #Optional helps save long term battery health
    #   START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
    #   STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging

    # };
  };

  system.stateVersion = "26.05";
}
