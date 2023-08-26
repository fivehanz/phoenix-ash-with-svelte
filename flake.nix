{
  description = "A Nix-flake-based Elixir development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = (with pkgs; [ asdf-vm nodejs_20 nodePackages.pnpm ]) ++
            # Linux only
            pkgs.lib.optionals (pkgs.stdenv.isLinux) (with pkgs; [ gigalixir inotify-tools libnotify ]) ++
            # macOS only
            pkgs.lib.optionals (pkgs.stdenv.isDarwin) (with pkgs; [ terminal-notifier ]) ++
            (with pkgs.darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices ]);

          shellHook = ''
            echo "asdf `${pkgs.asdf-vm}/bin/asdf --version`"
            echo "node `${pkgs.nodejs_20}/bin/node --version`"
          '';
        };
      });
    };
}
