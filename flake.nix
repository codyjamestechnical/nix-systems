{
  description = "Cody's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    webzfs = {
      url = "github:kaivalagi/webzfs";
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

    app-manager = {
      url = "github:kem-a/AppManager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

  };

  outputs = { self, nixpkgs, ssh-keys, webzfs, nixos-hardware, nix-flatpak, ... }@inputs: {
    nixosConfigurations = {
      mars-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
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
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/core-infra
          ./modules/tailscale.nix
          ./modules/docker.nix
        ];
      };

      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/laptop
          ./modules/app-manager.nix
          ./modules/desktop-base.nix
          nix-flatpak.nixosModules.nix-flatpak
        ];
      };

    };
  };
}
