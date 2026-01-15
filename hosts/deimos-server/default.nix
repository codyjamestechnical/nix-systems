{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./networking.nix
    ../../modules/core.nix
    ../../docker/komodo-periphery.nix
    ../../docker/beszel-agent.nix
  ];

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  # Network HostName
  networking.hostName = "deimos-server";

  fileSystems."/docker-data" = {
    device = "//u429456.your-storagebox.de/backup";
    fsType = "cifs";
    options =
      let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,file_mode=0750,dir_mode=0750,uid=995,gid=131,mfsymlinks,seal,noperm,nobrl";

      in
      [ "${automount_opts},credentials=/var/secrets/smb-secrets" ];
  };

  # ### SYNCTHING
  # services.syncthing = {
  #     enable = true;
  #     group = "root";
  #     systemService = true;
  #     settings = {
  #         key = "/var/secrets/syncthing/key.pem";
  #         cert = "/var/secrets/syncthing/cert.pem";
  #         devices = {
  #         "mars-server" = { id = "O3UVKX5-6TTVKEC-BDCBSW2-CAHTROG-ZE5UQLK-BHLVTQ6-USVBBRM-IT42CQW"; };
  #         };
  #         folders = {
  #             "test" = {
  #                 path = "/docker-data/syncthing-test";
  #                 devices = [ "mars-server"  ];
  #             };
  #             # "docker-data" = {
  #             #     path = "/docker-data";
  #             #     devices = [ "mars-server" "deimos-server" ];
  #             #     # By default, Syncthing doesn't sync file permissions. This line enables it for this folder.
  #             #     ignorePerms = false;
  #             # };
  #         };
  #     };
  # };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  system.stateVersion = "24.11";
}
