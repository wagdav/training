{
  description = "The contents of https://training.thewagner.net";

  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;

      forAllSystems = f:
        lib.genAttrs lib.systems.flakeExposed (system:
          f (import nixpkgs { inherit system; }));

      pythonEnvFor = pkgs: pkgs.python3.withPackages (ps: with ps; [
        markdown
        pelican
      ]);

    in
    {

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          buildInputs = [ (pythonEnvFor pkgs) pkgs.ghp-import ];
        };
      });

      packages = forAllSystems (pkgs: rec {
        default = site;

        site = pkgs.stdenv.mkDerivation {
          name = "training-thewagner-net-${self.shortRev or "dirty"}";

          nativeBuildInputs = [
            (pythonEnvFor pkgs)
          ];

          src = pkgs.lib.cleanSource self;

          dontBuild = true;

          installPhase = ''
            pelican \
              --fatal warnings \
              --settings publishconf.py \
              --output $out \
              content
          '';
        };
      });

      checks = forAllSystems (pkgs: {
        site = self.packages.${pkgs.system}.site;

        shellcheck = pkgs.runCommand "shellcheck"
          {
            buildInputs = with pkgs; [ shellcheck ];
          }
          ''
            mkdir $out
            shellcheck --shell bash ${./scripts}/*
          '';
      });
    };
}
