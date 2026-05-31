{
  description = "The contents of https://training.thewagner.net";

  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs { inherit system; };

      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        markdown
        pelican
      ]);

    in
    rec {

      devShells."${system}".default = pkgs.mkShell {
        buildInputs = [ pkgs.yarn pythonEnv pkgs.ghp-import ];
      };

      packages."${system}" = rec {
        default = site;

        site = pkgs.stdenv.mkDerivation {
          name = "training-thewagner-net-${self.shortRev or "dirty"}";

          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = self + "/yarn.lock";
            hash = "sha256-mQVVw0VDf+w5JwUrXNzxe8OFdfHvEhNMkwESiExQHm4=";
          };

          nativeBuildInputs = [
            pythonEnv
            pkgs.nodejs
            pkgs.yarn
            pkgs.yarnBuildHook
            pkgs.yarnConfigHook
          ];

          src = self;

          yarnBuildScript = "webpack";

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
