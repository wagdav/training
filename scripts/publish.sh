#! /usr/bin/env nix-shell
#! nix-shell ../shell.nix -i bash

set -eu

SITE=$(nix-build --no-out-link -A packages.x86_64-linux.site)
ghp-import -m "Automatic update" "$SITE"
git push --force origin gh-pages:gh-pages
