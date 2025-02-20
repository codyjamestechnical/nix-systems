{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = inputs@{ nixpkgs, sops-nix,... }: {
    nixosConfigurations = {
      mars-server = nixpkgs.lib.nixosSystem {
        #system = "x86_64-linux";
        modules = [
          ./hosts/mars-server
          sops-nix.nixosModules.sops
        ];
      };

      deimos-server = nixpkgs.lib.nixosSystem {
        #system = "x86_64-linux";
        modules = [
          ./hosts/deimos-server
          sops-nix.nixosModules.sops
          
        ];
      };
    };
  };
}