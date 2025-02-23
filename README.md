# nix-systems
 NixOS system flake configurations.

#cloud-config

runcmd:
  - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | PROVIDER=hetznercloud NIX_CHANNEL=nixos-23.05 bash 2>&1 | tee /tmp/infect.log