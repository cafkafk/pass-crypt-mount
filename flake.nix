{
  description = "A hastily written shell script for dealing with LUKS drives";

  # Nixpkgs / NixOS version to use.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, treefmt-nix }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        pass-crypt-mount = with final; stdenvNoCC.mkDerivation (finalAttrs: {
          pname = "pass-crypt-mount";
          version = "${version}";

          src = ./.;

          unpackPhase = ":";

          buildInputs = with pkgs; [makeWrapper fish pass ripgrep udisks cryptsetup sudo util-linux strace];

          buildPhase = "";

          installPhase =
            ''
              runHook preInstall

              mkdir -p $out/bin
              cp $src/cm $out/bin/

              runHook postInstall
            '';

          postInstall = ''
            wrapProgram "$out/bin/cm" \
              --prefix PATH : "${lib.makeBinPath [fish pass ripgrep udisks cryptsetup sudo util-linux]}"
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

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        {
          inherit (nixpkgsFor.${system}) pass-crypt-mount;
        });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems (system: self.packages.${system}.pass-crypt-mount);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.pass-crypt-mount =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [ self.overlay ];

          environment.systemPackages = [ pkgs.pass-crypt-mount ];

          #systemd.services = { ... };
        };

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems
        (system:
          with nixpkgsFor.${system};

          {
            inherit (self.packages.${system}) pass-crypt-mount;

            # Additional tests, if applicable.
            test = stdenv.mkDerivation (finalAttrs: {
              pname = "pass-crypt-mount";
              version = "${version}";

              buildInputs = [ pass-crypt-mount makeWrapper fish pass ripgrep udisks cryptsetup sudo util-linux];

              unpackPhase = "true";

              buildPhase = ''
                echo 'running some integration tests'
                diff -U3 --color=auto <(cm -h | head -n 1) <(echo 'cm - Crypt Mount 0.7.4');
              '';

              installPhase = "mkdir -p $out";
            });
          });
    };
}
