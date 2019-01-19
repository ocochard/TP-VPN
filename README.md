# TP VPN

TP sur les technos VPN pour classes de licences professionnelles: ASUR (Administration et Sécurité des Réseaux) et RIMS (Réseaux Informatiques Mobilité Sécurité).

## Préparation du TP

### Creation de l'image disque FreeBSD

(Une copie de cette image, compressée avec xz (environ 400Mo), est disponible [ici](http://gugus69.free.fr/IUT/FreeBSD12-iutstmalo.img.xz)).

Instructions de création de l'image à partir d'un poste FreeBSD avec bhyve:
* Création d'une VM avec un disque dur de taille 2Gib (1.9Go) (pour correspondre à la taille marketing des clés USB de 2Gib)
```
pkg install vm-bhyve
mkdir /home/olivier/VMs
sysrc vm_dir="/home/olivier/VMs"
vm init
echo 'disk0_size="2000000000"' >> /home/olivier/VMs/.templates/default.conf
vm switch create public
vm switch add public lagg0
vm iso ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/12.0/FreeBSD-12.0-RELEASE-amd64-disc1.iso
vm create iutstmalo
vm install iutstmalo FreeBSD-12.0-RELEASE-amd64-disc1.iso
vm console iutstmalo
```

Instruction de création de l'image à partir d'un MacOS avec xhyve:
```
brew install xhyve
mkdir -p $HOME/VMs/iutstmalo
cd $HOME/VMs/iutstmalo
cp /usr/local/opt/xhyve/share/xhyve/xhyverun-freebsd.sh .
curl ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/12.0/FreeBSD-12.0-RELEASE-amd64-disc1.iso --output FreeBSD-12.0-RELEASE-amd64-disc1.iso
mkfile 2000000000 disk0.img
sed -i "" -e '/BOOTVOLUME=/s/<path of FreeBSD iso>/FreeBSD-12.0-RELEASE-amd64-disc1.iso/' xhyverun-freebsd.sh
sed -i "" -e '/IMG=/s/<path of disk image for FreeBSD>/disk0.img/' xhyverun-freebsd.sh
sed -i "" -e 's/build\///' xhyverun-freebsd.sh
sed -i "" -e 's/test\//\/usr\/local\/opt\/xhyve\/share\/xhyve\/test\//' xhyverun-freebsd.sh
```

Pour les paramètres d'installation d'un FreeBSD sur cette image:
* Console type: par défaut (VT100)
* Install
* Continue with default keymap: La configuration du clavier français se fera plus tard
* Hostname: routeur.univ-rennes1.fr
* Choix des packages: Désélectionner kernel-dbg et lib32
* Partitionning: Manual, Create, MBR (DOS partitions), Create (freebsd), OK, selectionner la nouvelle partition s1, Create, Mountpoint: /, Finish, Commit
* Mot de passe root: stmalo
* Configurer le réseau pour l'installation des packages et scripts
* Configurer la timezone: Europe, France, Yes, Skip
* Services: Désactiver SSHD et dumpdev
* Sécurité: laisser par défaut
* Ajout d'utilisateur: non
* Exit (Apply configuration)
* Lancer un shell: NO
* Reboot ou LiveCD: LiveCD

```
login: root
tunefs -L rootfs /dev/vtbd0s1a
reboot
```

Redémarrer le système à la fin, puis se connecter en root sur la machine, télécharger et lancer le script de préparation du master:
* Modification du /etc/fstab pour utiliser le label UFS (/dev/ufs/rootfs) au lieu des noms des disques physique pour permettre de booter depuis une clé USB ensuite
* Personnalisation du système (clavier français)
* Création du compte etudiant/iut
* Installation des scripts serveur et tunnel

```
cd /tmp
fetch --no-verify-peer https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/preparation-master.sh
sh preparation-master.sh
shutdown -p now
```

### Transfert de l'image disque sur une clé USB (2Go)
Une fois terminé, l'image disque peux être transférée sur clé USB avec un simple dd (ou Win32 Disk Imager sous windows).
```
dd if=$HOME/VMs/iutstmalo/disk0.img of=/dev/da0 bs=512k
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
