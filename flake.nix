{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
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
        specialArgs = inputs;
        modules = [
          ./hosts/deimos-server
          
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