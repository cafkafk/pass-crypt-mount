{
  description = "A hastily written shell script for dealing with LUKS drives";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    systems,
    treefmt-nix,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = (import nixpkgs) {
          inherit system;
        };
        # to work with older version of flakes
        lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

        # Generate a user-friendly version number.
        version = builtins.substring 0 8 lastModifiedDate;

        # System types to support.
        supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

        # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
        forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

        # Nixpkgs instantiated for supported system types.
        nixpkgsFor = forAllSystems (system:
          import nixpkgs {
            inherit system;
            overlays = [self.overlay];
          });

        treefmtEval = treefmt-nix.lib.evalModule pkgs (import ./treefmt.nix {inherit pkgs;});
      in rec {
        packages = {
          default = with pkgs;
            stdenvNoCC.mkDerivation (finalAttrs: {
              pname = "pass-crypt-mount";
              version = "${version}";

              src = ./.;

              unpackPhase = ":";

              buildInputs = with pkgs; [makeWrapper fish pass ripgrep udisks cryptsetup sudo util-linux strace];

              dontBuild = true;

              installPhase = ''
                runHook preInstall

                mkdir -p $out/bin
                cp $src/pass-crypt-mount.fish $out/bin/crypt-mount
                cp $src/pass-crypt-mount.fish $out/bin/cm
                wrapProgram "$out/bin/cm" \
                  --prefix PATH : "${lib.makeBinPath [fish pass ripgrep udisks cryptsetup sudo util-linux]}"
                wrapProgram "$out/bin/crypt-mount" \
                  --prefix PATH : "${lib.makeBinPath [fish pass ripgrep udisks cryptsetup sudo util-linux]}"

                mkdir -p $out/lib/password-store/extensions/

                cp $out/bin/crypt-mount $out/lib/password-store/extensions/crypt-mount.bash
                cp $out/bin/cm $out/lib/password-store/extensions/cm.bash

                runHook postInstall
              '';

              doInstallCheck = true;

              installCheckPhase = ''
                runHook preInstallCheck

                diff -U3 --color=auto <($out/bin/cm -h | head -n 1) <(echo "cm - Crypt Mount 0.7.4");

                runHook postInstallCheck
              '';

              meta = with lib; {
                mainProgram = "cm";
              };
            });
          pass-crypt-mount = self.packages.${system}.default;
          pass-with-crypt-mount = pkgs.pass.withExtensions (e: [self.packages.${system}.pass-crypt-mount]);
        };

        nixosModules.pass-crypt-mount = {pkgs, ...}: {
          nixpkgs.overlays = [self.overlay];

          environment.systemPackages = [pkgs.pass-crypt-mount];

          #systemd.services = { ... };
        };

        formatter = treefmtEval.config.build.wrapper;

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [fish];
        };

        checks = {
          formatting = treefmtEval.config.build.check self;
          default = packages.default;
        };
      }
    );
}
