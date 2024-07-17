# The flake interface to llama.cpp's Nix expressions. The flake is used as a
# more discoverable entry-point, as well as a way to pin the dependencies and
# expose default outputs, including the outputs built by the CI.

# For more serious applications involving some kind of customization  you may
# want to consider consuming the overlay, or instantiating `llamaPackages`
# directly:
#
# ```nix
# pkgs.callPackage ${llama-cpp-root}/.devops/nix/scope.nix { }`
# ```

# Cf. https://jade.fyi/blog/flakes-arent-real/ for a more detailed exposition
# of the relation between Nix and the Nix Flakes.
{
  description = "Weather Research & forcasting model (WRF)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  # For inspection, use `nix flake show github:abdalazizrashid/wrf` or the nix repl:
  #
  # ```bash
  # ❯ nix repl
  # nix-repl> :lf github:abdalazizrashid/wrf
  # Added ?? variables.
  # nix-repl> outputs.apps.??
  # ?????????????????????????????
  # ```
  outputs =
    { self, flake-parts, ... }@inputs:
    let
      # We could include the git revisions in the package names but those would
      # needlessly trigger rebuilds:
      # wrfVersion = self.dirtyShortRev or self.shortRev;

      # Nix already uses cryptographic hashes for versioning, so we'll just fix
      # the fake semver for now:
      wrfVersion = "0.0.0";
    in
    flake-parts.lib.mkFlake { inherit inputs; }

      {

        imports = [
          ./nix/nixpkgs-instances.nix
        ];

        flake.overlays.default = (
          final: prev: {
            wrfPackages = final.callPackage nix/scope.nix { inherit wrfVersion; };
            inherit (final.wrfPackages) wrf;
          }
        );

        systems = [
          "aarch64-darwin"
          "aarch64-linux"
          "x86_64-darwin"
          "x86_64-linux"
        ];

        perSystem =
          {
            config,
            lib,
            system,
            pkgs,
            ...
          }:
          {
            # For standardised reproducible formatting with `nix fmt`
            formatter = pkgs.nixfmt-rfc-style;

            # Unlike `.#packages`, legacyPackages may contain values of
            # arbitrary types (including nested attrsets) and may even throw
            # exceptions. This attribute isn't recursed into by `nix flake
            # show` either.
            #
            # You can add arbitrary scripts to `nix/scope.nix` and
            # access them as `nix build .#wrfPackages.${scriptName}` using
            # the same path you would with an overlay.
            legacyPackages = {
              wrfPackages = pkgs.callPackage nix/scope.nix { inherit wrfVersion; };
            };

            # We don't use the overlay here so as to avoid making too many instances of nixpkgs,
            # cf. https://zimbatm.com/notes/1000-instances-of-nixpkgs
            packages =
              {
                default = config.legacyPackages.wrfPackages.wrf;
              }
              // lib.optionalAttrs pkgs.stdenv.isLinux {
                mpi-cpu = config.packages.default.override { useMpi = true; };
              }
              // lib.optionalAttrs (system == "x86_64-linux") {
              };
            # TODO: whats up with checks?
            # Packages exposed in `.#checks` will be built by the CI and by
            # `nix flake check`.
            #
            # We could test all outputs e.g. as `checks = confg.packages`.
            #
            checks = {
              inherit (config.packages) default;
            };
          };
      };
}
