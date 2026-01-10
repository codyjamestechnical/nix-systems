{ borgBackup, config, ... }:
{
  services.borgbackup.jobs.main-backup = {
    paths = borgBackup.paths;
    repository = borgBackup.repository;
    encryption.mode = "none";
    environment.BORG_RSH = "ssh -i /root/.ssh/id_ed25519";
    compression = "auto,zstd";
    startAt = "daily";
    prune.keep.daily = 4;
  };
}