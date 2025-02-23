{ lib, ... }: {
  # This file was populated at runtime with the networking
  # details gathered from the active system.
  networking = {
    nameservers = [ "8.8.8.8"
 ];
    defaultGateway = "172.31.1.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    dhcpcd.enable = false;
    usePredictableInterfaceNames = lib.mkForce false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          { address="162.55.36.190"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="2a01:4f8:c013:9662::1"; prefixLength=64; }
{ address="fe80::9400:4ff:fe17:c056"; prefixLength=64; }
        ];
        ipv4.routes = [ { address = "172.31.1.1"; prefixLength = 32; } ];
        ipv6.routes = [ { address = "fe80::1"; prefixLength = 128; } ];
      };
            enp7s0 = {
        ipv4.addresses = [
          { address="10.0.0.2"; prefixLength=32; }
        ];
        ipv6.addresses = [
          { address="fe80::8400:ff:fed5:55ae"; prefixLength=64; }
        ];
        };
    };
  };
  services.udev.extraRules = ''
    ATTR{address}=="96:00:04:17:c0:56", NAME="eth0"
    ATTR{address}=="86:00:00:d5:55:ae", NAME="enp7s0"
  '';
}
