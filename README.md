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

### Rebuild
```
sudo nixos-rebuild switch
```

### Copy your hardware-configuration.nix & networking.nix
Use nano to copy your hardware-configuration.nix and your networking.nix files to the servers dierectory in this repo
```
sudo nano /etc/nixos/hardware-configuration.nix # then copy the text
```
Create a hardware-configuration.nix file in the servers directory in this repo and past the contents. Now do the same for networking if you are using nix-infect

### Clone This Repo
```
sudo git clone https://github.com/codyjamestechnical/nix-systems.git

```

### Rebuild nixos with the flake
```
sudo nixos-rebuild switch --flake "[path to nix-systems dir]#[system to build]

```
