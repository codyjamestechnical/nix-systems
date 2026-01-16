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
Place the secrets files in the /etc/nixos/secrets directory on the server for ACME Certs, Komodo Agent, and CIFS share creds. If you need to store more than 3 secrets I would consider moving to a secrets manager like SOPs.
```
# Create secrets directory
sudo mkdir /etc/nixos/secrets #Create Secrets Directory

#Create Files
sudo nano /etc/nixos/secrets/cloudflare-token # Paste in the cloudflare token for ACME
sudo nano /etc/nixos/secrets/komodo-passkey # Paste in Komodo agent passkey
sudo nano /etc/nixos/secrets/smb-secrets # Paste in the CIFS share login

# Set Permissions
sudo chown root:root -R /etc/nixos/secrets #set owner and group to root
sudo chmod 660 -R /etc/nixos/secrets  #Set permissions on folder and files so that only root has access
```

### Clone This Repo
```
sudo git clone https://github.com/codyjamestechnical/nix-systems.git
```

### Rebuild nixos with the flake
```
sudo nixos-rebuild switch --flake "[path to nix-systems dir]#[system to build]
```

### Set password for your user
```
sudo passwd [your-user] # set password of main user
```

### Login to Tailscale
```
sudo tailscale up --ssh --accept-dns --advertise-exit-node
```

```
#cloud-config

write_files:
runcmd:
  - curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | PROVIDER=hetznercloud NIX_CHANNEL=nixos-25.11 NO_REBOOT=true bash -x \
  &&  { cat > /etc/nixos/configuration.nix << 'EOF'
    { ... }: {
    imports = [
      ./hardware-configuration.nix
      ./networking.nix # generated at runtime by nixos-infect
     
    ];

    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;
    networking.hostName = "deimos-server";
    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAIEB06+mXFpYiRLegmXjiZzPuF1rTs+ySVCn5mJ0hpZ cody@cjtech.io'' ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    programs.git.enable = true;

    system.stateVersion = "25.11";
    }
    
    }
  EOF \
  && /root/.nix-profile/bin/nix build \
  result/activate
  result/bin/switch-to-configuration switch
  - git clone https://github.com/codyjamestechnical/nix-systems.git /etc/nixos
  - mkdir /etc/nixos/secrets
  - touch /etc/nixos/secrets/cloudflare-token
  - touch /etc/nixos/secrets/komodo-passkey
  - touch /etc/nixos/secrets/tailscale_key
  - chown root:root -R /etc/nixos/secrets
  - chmod 660 -R /etc/nixos/secrets
  - reboot

