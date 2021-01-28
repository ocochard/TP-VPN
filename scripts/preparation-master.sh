#!/bin/sh
set -eu

# Declaration d'un clavier AZERTY francais
sysrc keymap="fr.acc.kbd"

EASYRSA_DIR="/usr/local/share/easy-rsa"

# Acceleration du temps de demarage
sysrc -f /boot/loader.conf autoboot_delay="2"
#kld_list="/boot/modules/i915kms.ko"
sysrc -f /boot/loader.conf i915kms_load="YES"
sysrc -f /boot/loader.conf kern.vt.fb.default_mode="1024x768"
# Configuration d'un CLI en couleur par defaut et desactivation du beep
grep -q CLICOLOR /etc/csh.cshrc ||  echo "setenv CLICOLOR" >> /etc/csh.cshrc
grep -q nobeep /etc/csh.cshrc || echo "set nobeep" >> /etc/csh.cshrc

# Creation du compte etudiant et ajout dans le groupe wheel
if ! grep -q etudiant /etc/passwd; then
	echo "etudiant::::::::/bin/csh:iut" > /tmp/ajout.user
	adduser -f /tmp/ajout.user
	pw usermod etudiant -G wheel
fi

echo "Installation des packages"
PKG_LIST='
ca_root_nss
tmux
openvpn
mohawk
w3m
vim-console
nano
en-freebsd-doc
drm-kmod
'

ASSUME_ALWAYS_YES=yes
export ASSUME_ALWAYS_YES
pkg bootstrap
for PACKAGE in ${PKG_LIST}; do
  pkg info ${PACKAGE} || pkg install -y ${PACKAGE}
done

# Configuration du dossier PKI pour easyrsa
echo 'set_var EASYRSA_PKI             "$EASYRSA/pki"' >> /usr/local/share/easy-rsa/vars

mkdir /home/etudiant/handbook
cd /home/etudiant/handbook
fetch https://download.freebsd.org/ftp/doc/handbook/book.html.tar.bz2
tar xzfv book.html.tar.bz2
cat <<EOF > /etc/motd.template

Welcome to FreeBSD!

FreeBSD Handbook: https://www.FreeBSD.org/handbook

Local copy of this handbook is available, readable with this command:
w3m /usr/local/share/doc/freebsd/en/books/handbook/index.html

EOF

cd /tmp
[ -f preparation-server.sh ] || fetch https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/preparation-server.sh
[ -f tunnels.sh ] || fetch https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/tunnels.sh

# Modification du fstab pour prendre en compte le label UFS
if grep -q rootfs /etc/fstab; then
	sed -i "" -e 's/vtbd0s1a/ufs\/rootfs/' /etc/fstab
fi
if grep -q noatime /etc/fstab; then
	sed -i "" -e 's/rw/rw,noatime/' /etc/fstab
fi
sysrc -x dumpdev
sed -i "" '/dumpdev/d' /etc/rc.conf

# Suppression de la configuration reseau
rm /etc/resolv.conf
sysrc -x ifconfig_vtnet0_ipv6 || true
sysrc -x ifconfig_vtnet0

