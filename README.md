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
sudo nano /etc/nixos/networking.nix ## then copy the text
```
Create a hardware-configuration.nix file in the servers directory in this repo and past the contents. Now do the same for networking if you are using nix-infect

### Create Secrets files
Place the secrets files in the /var/secrets directory on the server for ACME Certs, Komodo Agent, and CIFS share creds.
```
sudo mkdir /var/secrets #Create Secrets Directory
sudo nano /var/secrets/cloudflare-token # Paste in the cloudflare token for ACME
sudo nano /var/secrets/komodo-passkey # Paste in Komodo agent passkey
sudo nano /var/secrets/smb-secrets # Paste in the CIFS share login
```

### Clone This Repo
```
sudo git clone https://github.com/codyjamestechnical/nix-systems.git
```

### Rebuild nixos with the flake
```
sudo nixos-rebuild switch --flake "[path to nix-systems dir]#[system to build]
```

### Login to Tailscale
```
sudo tailscale up --ssh --accept-dns --advertise-exit-node
```
