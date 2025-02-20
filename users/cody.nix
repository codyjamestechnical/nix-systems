{ inputs, config, pkgs, ...}:
{

    users={
        defaultUserShell = pkgs.zsh;
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
            # openssh.authorizedKeys.keyFiles = [ inputs.ssh-keys.outPath ];
            # openssh.authorizedKeys.keyFiles = [
            #     (builtins.fetchurl { url = "https://github.com/codyjamestechnical.keys?1";})
            # ];
            openssh.authorizedKeys.keys = builtins.readFile (builtins.fetchurl https://github.com/codyjamestechnical.keys);
            packages = with pkgs; [
            ];
        };
      
    };

}