{
  description = "ngIRCd OCI image with pam_pwdfile (htpasswd-style PAM auth)";

  # Single input, no third-party flakes — keeps the trust surface minimal.
  # Tracks the current stable release: security fixes are backported here with
  # low churn, which suits an unattended auto-pulling deploy. Bumped weekly by
  # the update-flake-lock workflow.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      # The image is Linux-only; build hosts can be either arch.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ self.overlays.default ];
            }
          )
        );
    in
    {
      # The overlay is the idiomatic seam: it makes `pam_pwdfile` (and the
      # composed image) first-class members of the package set, so anything
      # built with `callPackage` can depend on them by name. Reusable verbatim
      # in a NixOS configuration's `nixpkgs.overlays`.
      overlays.default = final: prev: {
        pam_pwdfile = final.callPackage ./nix/pam_pwdfile.nix { };
        ngircd-image = final.callPackage ./nix/docker-image.nix { };
      };

      packages = forAllSystems (pkgs: {
        inherit (pkgs) pam_pwdfile;
        ngircd-image = pkgs.ngircd-image;
        default = pkgs.ngircd-image;
      });

      # `nix fmt` -> formats every .nix file in the repo.
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
    };
}
