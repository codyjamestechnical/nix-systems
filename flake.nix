{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    webzfs = {
        url = "github:aaron/webzfs/nix-webzfs";
        inputs.nixpkgs.follows = "nixpkgs";
    };

    ssh-keys = {
      url = "https://github.com/codyjamestechnical.keys";
      flake = false;
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ssh-keys,... }@inputs: {
    nixosConfigurations = {
      mars-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {

        };
        modules = [
          ./hosts/mars-server
          ./modules/tailscale.nix
          ./modules/docker.nix
          webzfs.nixosModules.webzfs
          nixos-hardware.nixosModules.minisforum-um790-pro
        ];
      };

      core-infra = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {

        };
        modules = [
          ./hosts/core-infra
          ./modules/tailscale.nix
          ./modules/docker.nix
        ];
      };

    };
  };
}
