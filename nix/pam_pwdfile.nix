{ lib, stdenv, fetchurl, linux-pam, libxcrypt }:

# pam_pwdfile: PAM module that authenticates against an Apache-style
# (htpasswd) username/crypted-password file, instead of the system passwd db.
# Upstream (Timo Weingärtner; orig. Charl P. Botha): https://git.tiwe.de/libpam-pwdfile.git
# This is the same source Debian's `libpam-pwdfile` package is built from.
#
# Not packaged in nixpkgs, so we vendor it here.
stdenv.mkDerivation (finalAttrs: {
  pname = "pam_pwdfile";
  version = "2.0";

  src = fetchurl {
    url = "https://git.tiwe.de/libpam-pwdfile.git/snapshot/libpam-pwdfile-${finalAttrs.version}.tar.gz";
    hash = "sha256-mBwoaSPCAY7Oy1AlugsnAg/6lk2LjUJv9YrX8VbnJCQ=";
  };

  # -lpam (linux-pam) and -lcrypt / crypt_r (libxcrypt, split out of glibc)
  buildInputs = [ linux-pam libxcrypt ];

  # The Makefile installs into $(DESTDIR)$(PAM_LIB_DIR); point it at $out.
  makeFlags = [ "PAM_LIB_DIR=${placeholder "out"}/lib/security" ];

  meta = {
    description = "PAM module to authenticate against an Apache-style password file";
    homepage = "https://git.tiwe.de/libpam-pwdfile.git/about/";
    # Dual-licensed: BSD-3-Clause OR GPL-2.0-or-later (standard Linux-PAM module terms).
    license = with lib.licenses; [ bsd3 gpl2Plus ];
    platforms = lib.platforms.linux;
  };
})
