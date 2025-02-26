{ config, pkgs, ...}:
{
    users={
        defaultUserShell = pkgs.zsh;
        groups = {
            acme.gid = 984;
            ssl.gid = 2012;
            docker.gid = 2013;
        };     

        users.docker = {
            isNormalUser = false;
            isSystemUser = true;
            uid = 2013;
            group = "docker";
            extraGroups = [
                "ssl"
            ];
        };
    };

}