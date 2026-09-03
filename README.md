# Training

The source of https://training.thewagner.net

# Development

## Updating the yarn offline cache hash

`flake.nix` pins a `yarnOfflineCache` hash. Whenever `yarn.lock` changes, that
hash must be updated or the build fails with a hash mismatch.

Print the new hash in the SRI form used by `flake.nix`:

```sh
nix shell nixpkgs#prefetch-yarn-deps --command prefetch-yarn-deps yarn.lock 2>&1 >/dev/null \
  | grep -E '^[0-9a-z]{52}$' \
  | xargs nix hash convert --hash-algo sha256 --to sri
```

`prefetch-yarn-deps` writes its nix32 hash to stderr alongside progress output,
hence the `2>&1 >/dev/null` and `grep`. Update the `hash` in the
`yarnOfflineCache` block of `flake.nix` with the result.

Behind a TLS-intercepting proxy, `prefetch-yarn-deps` fails with
`UNABLE_TO_GET_ISSUER_CERT_LOCALLY`. Point node at your corporate root
certificate by prefixing the command:

```sh
NODE_EXTRA_CA_CERTS=/path/to/corporate-root.crt nix shell ...
```
