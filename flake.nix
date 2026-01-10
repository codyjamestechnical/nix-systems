{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
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
            paths = "/docker-data";
            repository = "ssh://u429456-sub2@u429456-sub2.your-storagebox.de:23/docker-data";
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
      
    };
  };
}