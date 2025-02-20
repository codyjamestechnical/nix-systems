{ config, pkgs, ...}:
{
    users={
        defaultUserShell = pkgs.zsh;
        groups = {
            acme.gid = 984;
            ssl.gid = 2012;
        };     

        users.docker = {
            isNormalUser = false;
            isSystemUser = true;
            group = "docker";
            extraGroups = [
                "ssl"
            ];
        };
    };

}