FROM docker.io/library/debian:stable-slim
USER root
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends --no-install-suggests libpam-pwdfile ngircd tini
EXPOSE 6667 6697
USER irc
ENTRYPOINT [ "/usr/bin/tini", "--", "/usr/sbin/ngircd", "--nodaemon" ]

# config file in /etc/ngircd/
# pam file should be /etc/pamd.d/ngircd
# pam file should reference pam_pwdfile.so
# /lib/x86_64-linux-gnu/security/pam_pwdfile.so
