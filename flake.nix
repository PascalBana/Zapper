{
  description = "Rust + Bevy development flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };
  outputs = inputs: with inputs;
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

          # Define macOS-specific packages
          darwinPackages = pkgs.lib.optionalAttrs (pkgs.stdenv.isDarwin) (with pkgs.darwin.apple_sdk.frameworks; {
            additionalPackages = [ Security CoreServices CoreFoundation Foundation AppKit ];
          });

          # Define Linux-specific packages
          linuxPackages = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
            additionalPackages = with pkgs; [ libudev-zero alsa-lib pkg-config ];
          };

        in
        with pkgs;
        {
          devShells.default = mkShell {
            buildInputs = [
              rustToolchain
            ] ++ (linuxPackages.additionalPackages or []) # Include Linux-specific packages if on Linux
            ++ (darwinPackages.additionalPackages or []); # Include macOS-specific packages if on Darwin
            shellHook = ''
              export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
              echo "Loading Rust development environment"
            '';
          };
        }
      );
}

