#! /usr/bin/env nix-shell
#! nix-shell ../shell.nix -i bash
PORT=8000

yarn install --modules-folder output/node_modules

pelican \
  --output output \
  --settings pelicanconf.py \
  --port $PORT \
  --listen \
  --autoreload \
  content
