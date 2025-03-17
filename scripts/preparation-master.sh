#!/bin/sh
set -eu

# Declaration d'un clavier AZERTY francais
sysrc keymap="fr.acc.kbd"

EASYRSA_DIR="/usr/local/share/easy-rsa"

# Acceleration du temps de demarage
sysrc -f /boot/loader.conf autoboot_delay="1"
#echo 'hw.vga.textmode=0' >> /boot/loader.conf
#sysrc -f /boot/loader.conf i915kms_load="YES"
#echo 'kern.vt.fb.default_mode="1024x768"' >> /boot/loader.conf
# Configuration d'un CLI en couleur par defaut et desactivation du beep
(
echo "CLICOLOR=yes"
echo "export CLICOLOR"
) >> /etc/profile

# Creation du compte etudiant et ajout dans le groupe wheel
if ! grep -q etudiant /etc/passwd; then
	echo "etudiant::::::::/bin/sh:iut" > /tmp/ajout.user
	adduser -f /tmp/ajout.user
	pw usermod etudiant -G wheel
fi

echo "Installation des packages"
ASSUME_ALWAYS_YES=yes
export ASSUME_ALWAYS_YES
pkg bootstrap
pkg install -y ca_root_nss tmux openvpn mohawk w3m vim-tiny nano en-freebsd-doc

# Configuration du dossier PKI pour easyrsa
echo 'set_var EASYRSA_PKI             "$EASYRSA/pki"' >> /usr/local/share/easy-rsa/vars

cat <<EOF > /etc/motd.template

Bienvenu sur FreeBSD!

Le manuel FreeBSD: https://www.FreeBSD.org/handbook

Une copie du manuel est disponible localement, l'afficher par la commande suivante:
w3m /usr/local/share/doc/freebsd/en/books/handbook/index.html

EOF

service motd restart

cd /tmp
[ -f preparation-server.sh ] || fetch https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/preparation-server.sh
[ -f tunnels.sh ] || fetch https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/tunnels.sh

# Modification du fstab pour prendre en compte le label GPT
if grep -q vtbd0 /etc/fstab; then
	sed -i "" -e 's/vtbd0p2/gpt\/ROOT/' /etc/fstab
	sed -i "" -e 's/vtbd0p1/gpt\/EFI/' /etc/fstab
fi
if grep -q ada0 /etc/fstab; then
	sed -i "" -e 's/ada0p2/gpt\/ROOT/' /etc/fstab
	sed -i "" -e 's/ada0p1/gpt\/EFI/' /etc/fstab
fi
if !grep -q noatime /etc/fstab; then
	sed -i "" -e 's/rw/rw,noatime/' /etc/fstab
fi
sysrc -x dumpdev
sed -i "" '/dumpdev/d' /etc/rc.conf

# Que fait la desactivation de la souris ?
sysrc -x moused_nondefault_enable
# Suppression de la configuration reseau
rm /etc/resolv.conf
sysrc -x ifconfig_em0_ipv6 || true
sysrc -x ifconfig_em0 || true
sysrc -x ifconfig_vtnet0_ipv6 || true
sysrc -x ifconfig_vtnet0 || true
rm /etc/resolv.conf.bak
