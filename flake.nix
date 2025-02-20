{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    sops-nix.url = "github:Mic92/sops-nix";
    ssh-keys = {
      url = "https://github.com/codyjamestechnical.keys";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, sops-nix, ssh-keys,... } @inputs: let
      inherit (self) outputs;
    in {
      nixosConfigurations = {
        mars-server = nixpkgs.lib.nixosSystem {
          specialArgs = {inherit inputs outputs;};
          system = "x86_64-linux";
          modules = [
            ./hosts/mars-server/default.nix
            sops-nix.nixosModules.sops
          ];
        };

        deimos-server = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/deimos-server
            sops-nix.nixosModules.sops
            
          ];
        };
      };
    };
}