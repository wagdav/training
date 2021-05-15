#! /usr/bin/env nix-shell
#! nix-shell ../shell.nix -i bash
PORT=8000

yarn install
yarn run webpack

pelican \
  --output output \
  --settings pelicanconf.py \
  --port $PORT \
  --listen \
  --autoreload \
  content
