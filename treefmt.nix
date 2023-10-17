{pkgs}: {
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true; # nix
  };
  settings.formatter = {
    "fish_sanity" = {
      command = pkgs.fish;
      options = [
        "-n"
      ];
      includes = ["*.fish"];
    };
  };
}
