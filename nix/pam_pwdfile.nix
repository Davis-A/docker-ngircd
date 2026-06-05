{ lib, stdenv, fetchurl, linux-pam, libxcrypt-legacy }:

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

  # -lpam (linux-pam) and -lcrypt / crypt_r. We use libxcrypt-LEGACY, not the
  # default libxcrypt: the default is built with a reduced hash set that omits
  # md5crypt ($1$) and sha256crypt ($5$). pam_pwdfile must verify whatever crypt
  # format is in the user's password file (e.g. `mkpasswd -m sha-256` -> $5$),
  # so it needs the full glibc-compatible hash set the legacy variant provides.
  buildInputs = [ linux-pam libxcrypt-legacy ];

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
