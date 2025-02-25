{inputs, outputs, lib, config, pkgs, ...}:
{
  users.users = {
    cody = {
      isNormalUser = true;
      extraGroups = [ 
        "wheel" 
        "networkmanager" 
        "docker" 
        "libvirtd" 
        "acme"
      ];
      openssh.authorizedKeys.keyFiles = [
        (builtins.fetchurl { url = "https://github.com/codyjamestechnical.keys?1";})
      ];
      home = "/home/cody";
      description = "Cody James";
      uid = 1000;
      shell = pkgs.zsh;
      packages = with pkgs; [
        git
        helix
        htop
        curl
        wget
        jq
        unzip
        zip
        tree
        nmap
        whois
        bind-utils
        dnsutils
        net-tools
        iputils
        iproute
        tcpdump
        traceroute
        mtr
        nethogs
        iftop
        iotop
        atop
        sysstat
        strace
        lsof
        ltrace
        ncdu
        pv
        rsync
        screen
        socat
        telnet
        tcpflow
        tcpick
        tcptrack
        tcpreplay
        tcpslice
        tcptraceroute
        tcptrack
        tcptrack
        tcptrack
        tc
        powerline-fonts
        lsd
        bat
        wget
        dua
        bfs
        pwgen
        zsh-powerlevel10k
        nurl
        nerdfonts
        direnv
        zsh
      ];

    };
  };

  environment.variables = {
    EDITOR = "${pkgs.helix}/bin/helix";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompletion = true;
    enableGlobalRc = true;
    enableRc = true;
    enableTheme = true;
    theme = "powerlevel10k/powerlevel10k";
    histSize = 10000;
  
    autosuggestions.enable = true;
    shellAliases = {
      runsrvc = "sudo systemctl start";
      stopsrvc = "sudo systemctl stop";
      resrvc = "sudo systemctl restart";
      ls = "lsd -lA";
      rebuild = "sudo nixos-rebuild switch";
      cat = "bat";

      
    };
  };

}