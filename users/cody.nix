{ config, pkgs, ...}:
{
    users={
        defaultUserShell = pkgs.zsh;
        groups = {
            acme.gid = 984;
            ssl.gid = 2012;
        };
     
        users.cody = {
            isNormalUser = true;
            description = "Cody";
            extraGroups = [ 
                "networkmanager" 
                "wheel"
                "docker"
                "libvirtd"
                "acme"
            ];
            shell = pkgs.zsh;
            openssh.authorizedKeys.keyFiles = [
                (builtins.fetchurl { url = "https://github.com/codyjamestechnical.keys?1";})
            ];

            packages = with pkgs; [
            ];
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