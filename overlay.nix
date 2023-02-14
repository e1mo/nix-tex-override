final: prev: let
  pname = "markdown";
  year = "2023";
  month = "02";
  day = "03";

  # Taken from the "name markdown" section in
  # https://texlive.info/tlnet-archive/<year>/<month>/<day>/tlnet/tlpkg/texlive.tlpdb.xz
  semVer = "2.20.0-0-gf64ade1";
  rev = 65715;
  version = "${semVer}-${toString rev}";
  urlp = "https://texlive.info/tlnet-archive/${year}/${month}/${day}/tlnet/archive/${pname}";

  # After updating year, month, day, semVer and rev these hashes need to be updated
  # To find the correct ones, change all of these hashes to prev.lib.fakeSha256 and then simply run
  # ```bash
  # nix build --impure --file example.nix markdown.pkgs --keep-going
  # error: hash mismatch in fixed-output derivation '/nix/store/s4qig473razyppnm96ydc3aamr6g510f-markdown.doc.r65715.tar.xz.drv':
  #          specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  #             got:    sha256-iaa6ZSQi1dZ8YDr9kxsh3KYeC7LFCPlP3/c3Sr4Ypv4=
  # error: hash mismatch in fixed-output derivation '/nix/store/k42sjpkks969n2ipz8n6mn2azsam4s7j-markdown.r65715.tar.xz.drv':
  #          specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  #             got:    sha256-my/hjhUIgMHmp0/tGGWctvIP5FEhVNIQcN/zoeCH6Sw=
  # error: hash mismatch in fixed-output derivation '/nix/store/vcz5yrslhzyh6kk9cr4gj39v0qpd81qg-markdown.source.r65715.tar.xz.drv':
  #          specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
  #             got:    sha256-GaZ6C2tUamVq7hqJxK5qdFlL9chCVWUYQ5KBiRQ15ws=
  # error: 1 dependencies of derivation '/nix/store/7q9k4gbkd4a3mqlcaxfmv0bf6dprb4y7-texlive-markdown-2.20.0-0-gf64ade1.drv' failed to build
  # ```
  # the markdown.r<rev> (so no source or doc part in there) will be the run hash
  tlTypes = {
    doc     = "sha256-iaa6ZSQi1dZ8YDr9kxsh3KYeC7LFCPlP3/c3Sr4Ypv4=";
    run     = "sha256-my/hjhUIgMHmp0/tGGWctvIP5FEhVNIQcN/zoeCH6Sw=";
    source  = "sha256-GaZ6C2tUamVq7hqJxK5qdFlL9chCVWUYQ5KBiRQ15ws=";
  };

  mkPkg = tlType: sha256: let
    tlSuffix = if tlType != "run" then ".${tlType}" else "";
    url = urlp + tlSuffix + ".r${toString rev}.tar.xz";
  in final.runCommand "texlive-${pname}${tlSuffix}-${semVer}" {
    src = final.fetchurl {
      inherit url sha256;
    };
    passthru = {
      inherit pname tlType version;
    };
  } ''
    mkdir $out

    tar -xf "$src" \
      --strip-components="0" \
      -C "$out" --anchored --exclude=tlpkg --keep-old-files
  '';
in {
  texlive = prev.texlive // {
    markdown.pkgs = final.lib.mapAttrsToList mkPkg tlTypes;
    combined = prev.texlive.combined // {
      scheme-full = prev.texlive.combine {
        inherit (prev.texlive) scheme-full;
        inherit (final.texlive) markdown;
        extraName = "full";
          # Include all core packages...
          pkgFilter = pkg: pkg.pname == "core" || (
            # ...and every packae of type run or bin as long as is itsn't markdown with a different version than the one we're building
            # We need to filter that out to avoid collisions between the old and the newer version
            final.lib.elem pkg.tlType [ "run" "bin" ] && !(final.lib.hasPrefix pname pkg.pname && pkg.version != version)
          );
        };
      };
    };
  }
