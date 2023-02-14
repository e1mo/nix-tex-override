{ nixpkgs ? <nixpkgs> }:

with import nixpkgs {};

let
	pname = "markdown";
	year = "2023";
	month = "02";
	day = "03";
	# Taken from the "name markdown" section in
	# https://texlive.info/tlnet-archive/2023/02/03/tlnet/tlpkg/texlive.tlpdb.xz
	semVer = "2.20.0-0-gf64ade1";
	rev = 65715;

	version = "${semVer}-${toString rev}";
	tlTypes = [ "run" "doc" "source" ];
	url = tlType: "https://texlive.info/tlnet-archive/${year}/${month}/${day}/tlnet/archive/${urlName tlType}.r${toString rev}.tar.xz";
	urlName = tlType: pname + lib.optionalString (tlType != "run") ".${tlType}";

	# After updating year, month, day, semVer and rev these hashes need to be updated
	# To find the correct ones, simply run
	# ```bash
	# nix build --file markdown.nix --impure --keep-going allMarkdown
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
	hashes = {
		doc = "sha256-iaa6ZSQi1dZ8YDr9kxsh3KYeC7LFCPlP3/c3Sr4Ypv4=";
		run = "sha256-my/hjhUIgMHmp0/tGGWctvIP5FEhVNIQcN/zoeCH6Sw=";
		source = "sha256-GaZ6C2tUamVq7hqJxK5qdFlL9chCVWUYQ5KBiRQ15ws=";
	};

	# More or less taken from
	# <https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/typesetting/tex/texlive/default.nix#L137-L183>
	mkPkg = tlType: runCommandLocal "texlive-${pname}-${semVer}" {
		src = fetchurl {
			url = url tlType;
			sha256 = hashes.${tlType};
		};
		passthru = {
			inherit pname tlType;
			version = version;
		};
	} ''
		mkdir $out

		tar -xf "$src" \
			--strip-components="0" \
			-C "$out" --anchored --exclude=tlpkg --keep-old-files
	'';

	# Buid a simple test pdf and run minimal checks on it
	testPdf = runCommand "test.pdf" {
		nativeBuildInputs = [ (mkCombined "full") pdfminer ];
		testTex = ./test.tex;
	} ''
		export TEXMFHOME=$(pwd)
		export TEXMFVAR=$(pwd)/texmf-var
		cp ${./test.tex} ./test.tex
		lualatex test.tex

		# Test if the bug fixed in
		# https://github.com/Witiko/markdown/commit/ad3407bc489ad6d60060e8a4d3efd893086682cf
		# is no longer present, thus our update is successfull
		pdf2txt test.pdf | grep "::" && exit 1

		touch $out
	'';
	
	# Due to how the tex packaging in nix works
	# each package actually is a list of each part (here run, doc, source)
	allPkgs = map mkPkg tlTypes;
	mkCombined = ver: texlive.combine {
		extraName = "combined-${ver}-custom";
		"scheme-${ver}" = texlive."scheme-${ver}";
		# Include all core packages...
		pkgFilter = pkg: pkg.pname == "core" || (
			# ...and every packae of type run or bin as long as is itsn't markdown with a different version than the one we're building
			# We need to filter that out to avoid collisions between the old and the newer version
			lib.elem pkg.tlType [ "run" "bin" ] && !(lib.hasPrefix pname pkg.pname && pkg.version != version)
				
		);
		markdown.pkgs = allPkgs;
	};
in {
	# For testing
	small = mkCombined "small";
	full = mkCombined "full";
	allMarkdown = allPkgs;
	testPdf = testPdf;
}