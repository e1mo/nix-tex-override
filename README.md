## Use as nix overlay (recommended)

[Nix overlays], here defined in `overlay.nix`,  are an easy way to extend nixpkgs in a clean matter. The provided overlay can be used as demonstrated in `example.nix`.
This overlay can be used as an external dependency like this:

```nix
with import <nixpk> {
  overlays = [(
    # Basically this is the only part different from the example.nix
    import (fetchurl {
      url = "https://raw.githubusercontent.com/e1mo/nix-tex-override/main/overlay.tex";
      sha256 = "...";
    });
  )];
};

stdenv.makeDerivation {
  name = "...";
  # ...
}
```

Of course you can also simply just copy the `overlay.nix` into the source.

## Building the example

To e.g. update the markdown version, simply run (for updating remember to replace the hashes as outlined in `overlay.nix`):

```shell
nix build --impure --file example.nix markdown.pkgs --keep-going
```

To see if building a PDF using the markdown works:

```shell
nix build --impure --file example.nix
```
