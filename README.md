# Training

The source of https://training.thewagner.net

# Development

The site is built with [Pelican](https://getpelican.com/). GPX trace maps use
[Leaflet](https://leafletjs.com/) loaded from a CDN at runtime, so there is no
JavaScript build step.

Start a local autoreloading server:

```sh
scripts/devserver.sh
```

Build the site with Nix:

```sh
nix-build -A packages.x86_64-linux.site
```
