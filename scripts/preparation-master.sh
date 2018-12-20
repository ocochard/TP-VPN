#!/bin/sh
set -eu

# Declaration d'un clavier AZERTY francais
sysrc keymap="fr.iso.acc"

EASYRSA_DIR="/usr/local/share/easy-rsa"

# Acceleration du temps de demarage
sysrc -f /boot/loader.conf autoboot_delay="2"

# Configuration d'un CLI en couleur par defaut et desactivation du beep
grep -q CLICOLOR /etc/csh.cshrc ||  echo "setenv CLICOLOR" >> /etc/csh.cshrc
grep -q nobeep /etc/csh.cshrc || echo "set nobeep" >> /etc/csh.cshrc

# Creation du compte etudiant
if ! grep -q etudiant /etc/passwd; then
	echo "etudiant::::::::/bin/csh:iut" > /tmp/ajout.user
	adduser -f /tmp/ajout.user
fi

echo "Installation des packages"
PKG_LIST='
ca_root_nss
tmux
openvpn
mohawk
w3m
vim-console
'

ASSUME_ALWAYS_YES=yes
export ASSUME_ALWAYS_YES
pkg bootstrap
for PACKAGE in ${PKG_LIST}; do
  pkg info ${PACKAGE} || pkg install -y ${PACKAGE}
done

x
#if [ -d ${EASYRSA_DIR} ]; then
#  echo "Converting easy-rsa bash script to tcsh script"
#  sed 's/export/setenv/;s/=/ /' ${EASYRSA_DIR}/vars > ${EASYRSA_DIR}/vars.tcsh 
#  mv ${EASYRSA_DIR}/vars ${EASYRSA_DIR}/vars.bash.old
#  mv ${EASYRSA_DIR}/vars.tcsh ${EASYRSA_DIR}/vars
#else
#  echo "ERROR: No easy-RSA installed?"
#fi

cd /tmp
[ -f preparation-server.sh ] || fetch http://dev.bsdrp.net/scripts/TP/preparation-server.sh
[ -f tunnels.sh ] || fetch http://dev.bsdrp.net/scripts/TP/tunnels.sh

# Modification du fstab pour prendre en compte le label UFS
tunefs -p /dev/vtbd0s1a > /tmp/tunefs.txt 2>&1
if grep -q rootfs /tmp/tunefs.txt; then
	sed -i "" -e 's/vtbd0s1a/ufs\/rootfs/' /etc/fstab
	sed -i "" -e 's/rw/rw,noatime/' /etc/fstab
fi
rm /tmp/tunefs.txt

# Suppression de la configuration reseau
sysrc -x ifconfig_vtnet0_ipv6
sysrc -x ifconfig_vtnet0

