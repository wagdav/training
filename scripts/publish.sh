#! /usr/bin/env nix-shell
#! nix-shell ../shell.nix -i bash

set -eu

nix-build
ghp-import -m "Automatic update" ./result
git push origin gh-pages
