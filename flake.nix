{
  description = "The contents of https://training.thewagner.net";

  inputs.nixpkgs.url = "nixpkgs/nixos-20.09";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs { inherit system; };

      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        markdown
        pelican
      ]);

      yarnEnv = pkgs.mkYarnModules rec {
        name = "training-thewagner-net-1.0.0";
        pname = "training-thewagner-net";
        packageJSON = ./package.json;
        yarnLock = ./yarn.lock;
        version = "1.0.0";
      };

    in
    rec {

      devShell."${system}" = pkgs.mkShell {
        buildInputs = [ pkgs.yarn pythonEnv pkgs.ghp-import ];
      };

      defaultPackage."${system}" = packages."${system}".site;

      packages."${system}" = {
        site = pkgs.stdenv.mkDerivation {
          name = "training-thewagner-net-${self.shortRev or "dirty"}";

          nativeBuildInputs = [ pythonEnv pkgs.yarn ];

          src = self;

          buildPhase = ''
            cp -r ${yarnEnv}/node_modules .
            yarn \
              --non-interactive \
              --offline \
              run webpack
          '';

          installPhase = ''
            pelican \
              --fatal warnings \
              --settings publishconf.py \
              --output $out \
              ${./content}
          '';
        };
      };

      checks."${system}" = {
        shellcheck = pkgs.runCommand "shellcheck"
          {
            buildInputs = with pkgs; [ shellcheck ];
          }
          ''
            mkdir $out
            shellcheck --shell bash ${./scripts}/*
          '';
      };
    };
}
