{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ssh-keys = {
      url = "https://github.com/codyjamestechnical.keys";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, ssh-keys,... }@inputs: {
    nixosConfigurations = {
      mars-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mars-server/default.nix
        ];
      };

      deimos-server = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        
        specialArgs = {
          borgBackup = {
            paths = "/root";
            repo = "ssh://u429456-sub2@u429456-sub2.your-storagebox.de:23/./backup-deimos-server";
          };
        };
        modules = [
          ./hosts/deimos-server
          ./modules/borg-backup.nix
        ];
      };

      komodo-server = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/komodo-server
        ];
      };

      core-infra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          tailscale-config = {
            advertise-tags = "tag:core-infra,tag:servers";
          };
        };
        modules = [
          ./hosts/core-infra
          sops-nix.nixosModules.sops
          ./modules/tailscale.nix
          ./modules/docker.nix

        ];
      };

      backup-server = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          tailscale-config = {
            advertise-tags = "tag:core-infra,tag:servers";
          };
        };
        modules = [
          ./hosts/headscale-server
          ./modules/tailscale.nix
          ./modules/docker.nix

        ];
      };
      
    };
  };
}
sudo sh -c 'cat << EOF >> authorized_keys ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGCkSW5nvvsulofc9hohfwCc6nznIS2ZjJ43ogyD09Dt core-infra@cjtech.io EOF'

87 85