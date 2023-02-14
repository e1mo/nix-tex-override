## Build latex-schemes

```bash
# "Build" (aka. download and unpack) all of the markdown packages components (usefull when updating hashes)
nix build --impure --file markdown.nix allMarkdown

# texlive-combined-small (usefull to see if building works at all)
nix build --impure --file markdown.nix small
 # texlive-combined-full (texlive distribution with all required dependencies)
nix build --impure --file markdown.nix full

# Build a simple test to ensure we didn't brick the markdown package
nix build --impure --file markdown.nix testPdf
```

