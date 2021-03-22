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
        buildInputs = [ pkgs.yarn pythonEnv pkgs.ghp-import];
      };

      defaultPackage."${system}" = packages."${system}".training-thewagner-net;

      packages."${system}" = {
        training-thewagner-net = pkgs.runCommand "pelican"
          {
            preferLocalBuild = true;
            buildInputs = [ pythonEnv ];
          }
          ''
            ln --symbolic ${./theme} theme
            ln --symbolic ${./pelicanconf.py} pelicanconf.py
            ln --symbolic ${./publishconf.py} publishconf.py

            pelican \
              --fatal warnings \
              --settings publishconf.py \
              --output $out \
              ${./content}

            cp -r ${yarnEnv}/node_modules $out/

            mkdir -p $out/deps/training-thewagner-net
          '';
      };

      checks."${system}" = {

        build = self.defaultPackage."${system}";

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
