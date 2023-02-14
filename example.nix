{ nixpkgs ? <nixpkgs> }:

with import nixpkgs {
  overlays = [ (import ./overlay.nix) ];
};

stdenv.mkDerivation  {
  name = "markdown-example-latex.pdf";
  src = fetchFromGitHub {
    owner = "Witiko";
    repo = "markdown";
    rev = "f64ade1d989610b490d880549100d62f02745b75";
    hash = "sha256-RN3f4JVmqsG7WUnv9ysj8xtnEgNBtubq4WbQRqjYeqI=";
  };
  sourceRoot = "source/examples";
  nativeBuildInputs = [ texlive.combined.scheme-full ];
  buildPhase = ''
    TEXMFHOME=$(pwd) TEXMFVAR=$(pwd)/texmf-var lualatex latex.tex
  '';
  installPhase = ''
    cp latex.pdf $out
  '';
  passthru = {
    # To make updating easier (See note in overlay.nix)
    inherit (texlive) markdown;
  };
}
