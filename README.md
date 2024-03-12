# TP VPN

TP sur les technologies VPN pour classes de licences professionnelles styles ASUR (Administration et Sécurité des Réseaux) et RIMS (Réseaux Informatiques Mobilité Sécurité).

## Préparation du TP

### Creation de l'image disque FreeBSD

Note: Une copie de cette image, compressée avec xz (environ 400Mo), est disponible [ici](http://gugus69.free.fr/IUT/FreeBSD14-UEFI-iutstmalo.img.xz).

Création d'une VM avec un disque dur de taille 2Gib (1.9Go) (pour correspondre à la taille marketing des clés USB de 2Gib).

Instructions de création de l'image à partir d'un poste FreeBSD avec l'hyperviseur bhyve:
```
pkg install vm-bhyve bhyve-firmware
mkdir $HOME/VMs
sysrc vm_dir="$HOME/VMs"
vm init
cat > $HOME/VMs/.templates/iut.conf <<EOF
loader="uefi"
cpu=4
cpu_sockets=1
cpu_cores=4
cpu_threads=1
memory=8G
network0_type="virtio-net"
network0_switch="public"
disk0_type="virtio-blk"
disk0_name="disk0.img"
disk0_size="2000000000"
EOF
vm switch create public
vm switch add public lagg0
vm iso https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-disc1.iso
vm create -t iut iutstmalo
vm install iutstmalo FreeBSD-14.0-RELEASE-amd64-disc1.iso
vm console iutstmalo
```

Instructions de création de l'image à partir d'un MacOS avec l'hyperviseur xhyve:
```
brew install hyperkit xz
curl -LO https://github.com/moby/hyperkit/raw/master/test/userboot.so
mkdir -p $HOME/VMs/iutstmalo
cp scripts/hyperkit-run.sh $HOME/VMs/iutstmalo
cd $HOME/VMs/iutstmalo
scp my-freebsd-machine-with-bhyve-firmware-installed:/usr/local/share/uefi-firmware/BHYVE_UEFI.fd .
curl https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-memstick.img.xz --output FreeBSD-14.0-RELEASE-amd64-memstick.img.xz
unxz FreeBSD-14.0-RELEASE-amd64-memstick.img.xz
mkfile 2000000000 disk0.img
sudo ./hyperkit-run.sh
```

Pour les paramètres d'installation d'un FreeBSD sur cette image:
* Console type: par défaut (VT100)
* Install
* Continue with default keymap: La configuration du clavier français se fera plus tard
* Hostname: routeur.univ-rennes1.fr
* Choix des packages: Désélectionner kernel-dbg et lib32
* Or Partitionning: Manual
  * Create GPT
  * Create first partition:
    * Type: efi
    * Size: 33MB
    * Mountpoint:
    * Label: EFI
  * Create second partition:
    * Type: freebsd-ufs (default)
    * Size: 1874MB (default)
    * Mountpoint: /
    * Label: ROOT
  * Finish, commit
* Mot de passe root: stmalo
* Configurer le réseau pour l'installation des packages et scripts: DHCP
* Configurer la timezone: Europe, France, Yes, Skip
* Services: Désactiver sshd et dumpdev, activer powerd
* Sécurité: laisser par défaut
* Ajout d'utilisateur: non
* Exit (Apply configuration)
* Do not log into shell

Redémarrer le système à la fin, puis se connecter en root sur la machine, télécharger et lancer le script de préparation du master:
* Modification du /etc/fstab pour utiliser les labels GPT(/dev/gpt/ROOT et /dev/gpt/EFI) au lieu des noms des disques physique pour permettre de booter depuis une clé USB ensuite
* Personnalisation du système (clavier français)
* Création du compte etudiant/iut
* Installation des scripts serveur et tunnel

```
cd /tmp
fetch https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/preparation-master.sh
sh preparation-master.sh
shutdown -p now
```

### Transfert de l'image disque sur une clé USB (2Go)
Une fois terminé, l'image disque peux être transférée sur clé USB avec un simple dd (ou Win32 Disk Imager sous windows).
Exemple depuis un FreeBSD:
```
dd if=$HOME/VMs/iutstmalo/disk0.img of=/dev/da0 bs=512k
```
Exemple depuis un MacOS:
```
diskutil list | grep external
diskutil unmountDisk disk4
sudo dd if=disk0.img of=/dev/rdisk4 bs=1m
```

### Génération du PDF de support de TP
Pour la converstion du document latex en pdf, depuis un FreeBSD (pkg install tex-formats tex-xetex) ou Mac (après avoir installé MacTex) il faut executer 2 fois xelatex pour la génération de la table des matières):
```
xelatex TP_GIF_SSH_OpenVPN.tex
xelatex TP_GIF_SSH_OpenVPN.tex
```

## Pendant le TP

### Configuration du concentrateur VPN

Une des machines sera la référence et concentrateur VPN, la démarrer avec la clé et lancer son script de configuration (création de 20 comptes utilisateurs et leurs clés SSH et certificats OpenVPN, configuration d'OpenVPN, des tunnels GIF et du serveur web).
```
cd /tmp
sh preparation-server.sh
```

### Script de monitoring et gestion des conflicts entre routes OpenVPN et GIF

Puis une fois configuré, il faut un deuxième script pour la gestion des conflicts de routes GIF & OpenVPN.
Ce script dois tourner en permanence, il permet de suivre aussi l'évolution des binômes:
```
cd /tmp
sh tunnels.sh
```
