{
  nixConfig.bash-prompt-prefix = ''(go) '';

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};

      pname = "zipalign";
      version = "0.0.0";
      root = ./.;
      drv = pkgs.stdenv.mkDerivation {
        inherit pname version;
        src = with pkgs.lib.fileset;
          toSource {
            inherit root;
            fileset = fileFilter (f: f.hasExt "go") root;
          };
        buildInputs = [pkgs.go];
        postPatch = ''go mod init github.com/mozilla-services/zipalign'';
        configurePhase = ''
          export GOCACHE=$TMPDIR/go-cache
          export GOPATH="$TMPDIR/go"
          export CGO_ENABLED=0
        '';
        buildPhase = ''
          export GOOS=android GOARCH=arm64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
          export GOOS=linux GOARCH=amd64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
          export GOOS=linux GOARCH=arm64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
          export GOOS=darwin GOARCH=amd64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
          export GOOS=darwin GOARCH=arm64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
          export GOOS=windows GOARCH=amd64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
          export GOOS=windows GOARCH=arm64
          go build -ldflags "-s -w" -o zipalign-$GOOS-$GOARCH
        '';
        installPhase = ''install -Dm755 -t $out zipalign-*'';
        __darwinAllowLocalNetworking = true;
      };
    in {
      packages.${pname} = drv;
      packages.default = inputs.self.packages.${system}.${pname};
      devShells.default = pkgs.mkShell {
        inputsFrom = [drv];
        shellHook = ''export PATH="$HOME/go/bin:$PATH"'';
      };
    });
}
