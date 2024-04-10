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
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustToolchain = pkgs.pkgsBuildHost.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;

        darwinPackages = pkgs.lib.optionalAttrs (pkgs.stdenv.isDarwin) (with pkgs.darwin.apple_sdk.frameworks; {
          additionalPackages = [ Security CoreServices CoreFoundation Foundation AppKit ];
        });

        linuxPackages = pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          additionalPackages = with pkgs; [
            libxkbcommon
            libudev-zero
            alsa-lib
            udev
            vulkan-loader
            xorg.libX11
            xorg.libXcursor
            xorg.libXi
            xorg.libXrandr
            #wayland
          ];
        };

      in with pkgs;
      {
        devShells.default = mkShell {
          nativeBuildInputs = [
            pkg-config
          ];
          buildInputs = [
            rustToolchain
          ] ++ (linuxPackages.additionalPackages or []) # Include Linux-specific packages if on Linux
          ++ (darwinPackages.additionalPackages or []); # Include macOS-specific packages if on Darwin

          shellHook = ''
            export LD_LIBRARY_PATH=${lib.makeLibraryPath (linuxPackages.additionalPackages or [])}
            export WINIT_UNIX_BACKEND=x11
            export NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1
            echo "Loading Bevy development environment"
          '';
        };
      }
    );
}
