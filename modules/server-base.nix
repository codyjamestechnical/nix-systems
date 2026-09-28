{config, pkgs, ...}:
{
  ### OpenSSH DEAMON ###
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  ### KERNAL MODULES ###
  boot.kernelModules = [
      # IPv4 legacy iptables modules
      "ip_tables"
      "iptable_filter"
      "iptable_nat"

      # IPv6 legacy iptables modules
      "ip6_tables"
      "ip6table_filter"
      "ip6table_nat"
  ];
  

}