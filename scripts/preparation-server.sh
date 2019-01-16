#!/bin/sh
#Preparation TP version 2019
set -eu

BIN_MAX=20
USER_FILE="/tmp/user.table"
EASYRSA_PKI="/usr/local/share/easy-rsa/pki"; export EASYRSA_PKI

# A usefull function (from: http://code.google.com/p/sh-die/)
die() { echo -n "EXIT: " >&2; echo "$@" >&2; exit 1; }

### Setting hostname
sysrc hostname="concentrateur.univ-rennes1.fr"
hostname concentrateur.univ-rennes1.fr

### Regenerate a new host ssh keys
echo "## Regenerate new host SSH keys ##"
if service sshd onestatus; then
	service sshd onestop || die "Can't stop SSHd"
fi
if [ -f /ssh_host_dsa_key.pub ]; then
	rm /etc/ssh/ssh_host_* || \
		die "Can't delete existing ssh key"
fi

service sshd onestart || \
	die "Can't start SSHd for generating host key"

service sshd onestop || die "Can't stop SSHd"

### Creating Users ###
echo "## Creating users ##"
[ -f $USER_FILE ] && rm -rf $USER_FILE

for i in `jot $BIN_MAX`; do
        #Generate user table for adduser
        #name:uid:gid:class:change:expire:gecos:home_dir:shell:password
        [ ! -d /home/succursale_$i ] && \
                echo "succursale_$i::::::::/bin/csh:$i" >> $USER_FILE
done
[ -f $USER_FILE ] && adduser -f $USER_FILE

### Generating server SSL certificate and client script
if [ ! -d ${EASYRSA_PKI} ];then
	mkdir ${EASYRSA_PKI}
	EASYRSA_BATCH=yes; export EASYRSA_BATCH
	easyrsa init-pki
	EASYRSA_REQ_CN="Universite Rennes1"; export EASYRSA_REQ_CN
	easyrsa build-ca nopass
	EASYRSA_REQ_CN="concentrateur"; export EASYRSA_REQ_CN
	easyrsa build-server-full concentrateur nopass
	easyrsa gen-dh
	mkdir -p /usr/local/etc/openvpn
	for FILE in ca.crt dh.pem issued/concentrateur.crt private/concentrateur.key; do
		cp ${EASYRSA_PKI}/${FILE} /usr/local/etc/openvpn
	done
fi

### Create /root/.ssh directory
# All users SSH keys will be put in /root/.ssh/authorized_keys
mkdir -p /root/.ssh
chmod -R 600 /root/.ssh

### OpenVPN base configuration generation
mkdir -p /usr/local/etc/openvpn/ccd
cat <<EOF > /usr/local/etc/openvpn/openvpn.conf
dev tun98
ca ca.crt
cert concentrateur.crt
key concentrateur.key
dh dh.pem
server 192.168.254.0 255.255.255.0
server-ipv6 fc00:254::/64
ifconfig-pool-persist ipp.txt
client-config-dir ccd
push "route 172.16.254.0 255.255.255.0"
push "route-ipv6 fc00:dead:beef::/64"
verb 4
keepalive 10 120
EOF

### Users main loop
for i in `jot $BIN_MAX`; do
	[ -f /home/succursale_$i/.ssh/authorized_keys ] && \
		rm /home/succursale_$i/.ssh/*
	su -l succursale_${i} -c 'ssh-keygen -b 4096 -f /home/$USER/.ssh/id_rsa -N ""'
	mkdir -p /tmp/succursale_$i/cles-ssh
	cp /etc/ssh/ssh_host_rsa_key.pub /tmp/succursale_$i/cles-ssh/cle_ssh_publique_concentrateur
	cp /home/succursale_${i}/.ssh/* /tmp/succursale_$i/cles-ssh/
	# Permit users to login as root with its SSH key
	cp /home/succursale_$i/.ssh/id_rsa.pub /home/succursale_$i/.ssh/authorized_keys
	if [ ! -f ${EASYRSA_PKI}/issued/succursale_$i.crt ];then
		EASYRSA_REQ_CN="succursale_$i"; export EASYRSA_REQ_CN
		easyrsa build-client-full succursale_$i nopass
		mkdir -p /tmp/succursale_$i/certifs-openvpn
		#Testing correct file size
		FILE_LIST="ca.crt issued/succursale_${i}.crt private/succursale_${i}.key"
		for file in ${FILE_LIST}; do
			[ -s ${EASYRSA_PKI}/${file} ] || \
		    die "Error with file ${EASYRSA_PKI}/${file}: Missing or empty"
			cp ${EASYRSA_PKI}/${file} /tmp/succursale_$i/certifs-openvpn/
		done
		tar -cf /tmp/succursale_${i}_cles.tgz -C /tmp/succursale_$i .
		rm -rf /tmp/succursale_$i
		echo "route 172.16.${i}.0 255.255.255.0" >> /usr/local/etc/openvpn/openvpn.conf
		echo "route-ipv6 fc00:${i}::/64" >> /usr/local/etc/openvpn/openvpn.conf
        echo "iroute 172.16.${i}.0 255.255.255.0" > /usr/local/etc/openvpn/ccd/succursale_${i}
		echo "iroute-ipv6 fc00:${i}::/64" >> /usr/local/etc/openvpn/ccd/succursale_${i}
        # Generate user OpenVPN configuration file (used by the teacher only!)
		cat <<EOF > /tmp/binome_${i}.openvpn.conf
client
proto udp
dev tun
remote 2.2.2.254
ca ca.crt
cert succursale_${i}.crt
key succursale_${i}.key
verb 4
keepalive 10 120
EOF

	fi
done

### Serveur virtuel derriere le concentrateur VPN et Tunnels GIFs
CLONED_IF_LIST="tap99"
for i in `jot $BIN_MAX`; do
	CLONED_IF_LIST="${CLONED_IF_LIST} gif${i}"
	sysrc ifconfig_gif${i}="inet 192.168.${i}.1/31 192.168.${i}.2 tunnel 2.2.2.254 2.2.2.${i} up"
	sysrc ifconfig_gif${i}_ipv6="inet6 fc00:bad:cafe:${i}::1 prefixlen 64"
done
echo "debug cloned_if_list: ${CLONED_IF_LIST}"
sysrc cloned_interfaces="${CLONED_IF_LIST}"
sysrc ifconfig_tap99="inet 172.16.254.1/24"
sysrc ifconfig_tap99_ipv6="inet6 fc00:dead:beef::1 prefixlen 64"
sysrc ifconfig_em1="inet 2.2.2.254/24"

service netif restart && \
	echo "Meet a problem for restarting/generating new interface"

### Activation du Routage
sysrc ipv6_activate_all_interfaces="YES"
sysrc gateway_enable="YES"
sysrc ipv6_gateway_enable="YES"
service routing restart && echo "Meet a problem for starting routing"

### Serveur SSH configuration
if ! grep -q "UseDNS no" /etc/ssh/sshd_config; then
	cat <<EOF >>/etc/ssh/sshd_config
#Permit to create SSH routed tunnels
PermitTunnel yes
PermitRootLogin yes
UseDNS no
LogLevel DEBUG
#Prevent user to play with the root account :-)
Match User root
        ChrootDirectory /var/empty
EOF
fi
### Serveur WWW
mkdir -p /usr/local/www
cat <<EOF > /usr/local/www/index.html
<html>
<head>
<title>Serveur Web TP/OpenVPN</title>
</head>
<body>
<br>
<p align="center"><b>Acces au serveur Web fonctionnel<b></p>
</body>
</html>
EOF

if [ ! -f /usr/local/etc/mohawk.conf ]; then
	cat <<EOF > /usr/local/etc/mohawk.conf
chroot /usr/local/www
user www
mime_type { html text/html txt text/plain }
vhost default {
        rootdir /
        dirlist off
        index_names { index.html index.htm default.html }
        status_url /status
}
EOF
fi

sysrc mohawk_enable="YES"
service mohawk restart && \
  echo "Warning: Can t restart WWW server!"

sysrc sshd_enable="YES"
service sshd restart && \
  echo "Warning: Can t reload sshd"

sysrc openvpn_enable="YES"
service openvpn restart && \
  echo "Warning: Can t reload openvpn"

echo "WARNING: NEED TO CHANGE ROOT password now!"

