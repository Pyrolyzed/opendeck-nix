{
  description = "OpenDeck - Linux software for the Elgato Stream Deck with support for original Stream Deck plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forEachSystem (pkgs: rec {
        opendeck = pkgs.callPackage ./pkg/package.nix { fodPkgs = pkgs; };
        default = opendeck;
      });

      # Build against the nixpkgs of the system this overlay is applied to, not the one pinned here.
      # WebKitGTK loads the EGL driver from /run/opengl-driver at runtime, which fails if that driver
      # needs a newer glibc than the one OpenDeck is linked against. The web process then aborts,
      # leaving a blank window. Only the FODs stick to the pinned nixpkgs to keep their hashes valid.
      overlays.default = final: _prev: {
        opendeck = final.callPackage ./pkg/package.nix {
          fodPkgs = nixpkgs.legacyPackages.${final.stdenv.hostPlatform.system};
        };
      };

      nixosModules.opendeck = {
        imports = [ ./module/opendeck.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };
      nixosModules.default = self.nixosModules.opendeck;
    };
}
