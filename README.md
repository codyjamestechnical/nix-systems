# nix-systems
 NixOS system flake configurations.


## Steps

### Hetzner Cloud Init
```
#cloud-config

runcmd:
  - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | PROVIDER=hetznercloud NIX_CHANNEL=nixos-23.05 bash 2>&1 | tee /tmp/infect.log

```
### Add lines to /etc/nixos/configuration.nix
```
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.git.enable = true;

```

### Clone This Repo
```
sudo git clone https://github.com/codyjamestechnical/nix-systems.git

```

