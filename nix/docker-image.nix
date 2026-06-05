{
  lib,
  dockerTools,
  writeTextDir,
  ngircd,
  tini,
  pam,
  pam_pwdfile,
  fakeNss,
}:

# The OCI image, composed entirely from the (overlaid) package set. Note how
# `pam_pwdfile` arrives as an ordinary argument alongside stock `ngircd`/`tini`
# — that is the overlay doing its job: our custom package is just another
# member of `pkgs`, wired in by `callPackage`.

let
  # PAM service file for ngIRCd. Unlike Debian, Nix has no global PAM module
  # search path, so each module is referenced by absolute store path — fully
  # deterministic. pam_pwdfile does the auth against an htpasswd-style file;
  # pam_permit (from linux-pam) satisfies the account stage ngIRCd also runs.
  pamd = writeTextDir "etc/pam.d/ngircd" ''
    auth     required  ${pam_pwdfile}/lib/security/pam_pwdfile.so pwdfile=/etc/ngircd/pwdfile
    account  required  ${pam}/lib/security/pam_permit.so
  '';

  # A minimal, valid sample config. Bind-mount your own ngircd.conf over
  # /etc/ngircd/ngircd.conf at runtime to override it.
  ngircdConf = writeTextDir "etc/ngircd/ngircd.conf" ''
    [Global]
        Name = irc.change.me
        Info = ngIRCd
        Ports = 6667

    [Options]
        PAM = yes
        PAMIsOptional = no
  '';
in
dockerTools.buildLayeredImage {
  name = "docker-ngircd";
  tag = "latest";

  contents = [
    ngircd
    tini
    pam_pwdfile # keeps the .so in the image closure (pamd references it)
    fakeNss # minimal /etc/passwd + /etc/group (provides root, nobody)
    pamd
    ngircdConf
  ];

  config = {
    Entrypoint = [
      "${tini}/bin/tini"
      "--"
      "${lib.getExe ngircd}"
      "--nodaemon"
    ];
    Cmd = [
      "--config"
      "/etc/ngircd/ngircd.conf"
    ];
    ExposedPorts = {
      "6667/tcp" = { }; # plaintext IRC
      "6697/tcp" = { }; # IRC-over-TLS
    };
    User = "nobody";
    Labels = {
      # Links the ghcr package to the repo (inherits its visibility/permissions).
      "org.opencontainers.image.source" = "https://github.com/davis-a/docker-ngircd";
      "org.opencontainers.image.description" = "ngIRCd with pam_pwdfile (htpasswd-style PAM auth)";
      "org.opencontainers.image.licenses" = "GPL-2.0-or-later";
    };
  };
}
