# TP: Déploiement et recette d'architecture sécurisée par VPN

Ce TP est destiné aux étudiants de Licence Professionnelle (BUT3) en Réseaux et Télécommunications (Cybersécurité).

## Objectifs Pédagogiques

Ce TP vous permettra de :
- Comprendre le fonctionnement des différentes technologies VPN
- Mettre en place et configurer des tunnels VPN avec différentes solutions (OpenVPN, GIF)
- Maîtriser les aspects sécurité dans la mise en place d'un VPN
- Appréhender l'administration système sous FreeBSD

## Environnement de Travail

Le TP s'effectue sur FreeBSD 14.2, un système d'exploitation Unix libre. Vous utiliserez une image système préparée spécifiquement pour ce TP.

### Image Système Préparée

Une image FreeBSD préconfigurée est disponible pour le TP :
- Taille : environ 400Mo (compressée)
- [Téléchargement direct](http://gugus69.free.fr/IUT/FreeBSD14-UEFI-iutstmalo.img.xz)

## Préparation du TP

### Creation de l'image disque FreeBSD

Création d'une VM avec un disque dur de taille 2Gib (1.9Go) (pour correspondre à la taille marketing des clés USB de 2Gib).

Instruction de création de l'image disque avec qemu (Linux, FreeBSD, MacOS):
```
fetch|wget|curl https://download.freebsd.org/releases/ISO-IMAGES/14.2/FreeBSD-14.2-RELEASE-amd64-disc1.iso.xz
unxz FreeBSD-14.2-RELEASE-amd64.disc1.iso.xz
qemu-img resize --shrink FreeBSD-14.2-RELEASE-amd64.raw 2G
truncate -s +2000000000 disk0.img
qemu-system-x86_64 --machine pc -cpu qemu64 -m 1G \
-display none -serial mon:stdio \
-netdev user,id=n1 -device virtio-net-pci,netdev=n1 \
-drive if=pflash,readonly=on,format=raw,file=/CHEMIN-COMPLET/edk2-x86_64-code.fd \
-drive if=virtio,file=FreeBSD-14.2-RELEASE-amd64-disc1.iso,format=raw,media=cdrom,read-only \
-drive if=virtio,file=disk0.img,format=raw,media=disk
```

Concernant le chemin complet (CHEMIN-COMPLET) de l'image firmware UEFI (edk2), elle se trouve en général ici:
- Linux: /usr/share/qemu/
- FreeBSD: /usr/local/share/qemu/
- MacOS: /opt/homebrew/Cellar/qemu/*/share/qemu/

#### Paramètres d'Installation FreeBSD

L'installation est configurée avec les paramètres suivants pour optimiser l'environnement de TP :
- Console type: par défaut (VT100)
- Install
- Continue with default keymap: La configuration du clavier français se fera plus tard
- Hostname: routeur.univ-rennes1.fr
- Choix des packages: Désélectionner kernel-dbg et lib32
- Or Partitionning: Manual
  - Create GPT
  - Create first partition:
    - Type: efi
    - Size: 33MB
    -  Mountpoint:
    -  Label: EFI
  - Create second partition:
    - Type: freebsd-ufs (default)
    - Size: 1874MB (default)
    - Mountpoint: /
    - Label: ROOT
  - Finish, commit
- Mot de passe root: stmalo
- Configurer le réseau pour l'installation des packages et scripts: DHCP
- Configurer la timezone: Europe, France, Yes, Skip
- Services: Désactiver sshd et dumpdev, activer powerd
- Sécurité: laisser par défaut
- Ajout d'utilisateur: non
- Exit (Apply configuration)
- Do not log into shell

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
dd if=disk0.img of=/dev/da0 bs=1m
```
Exemple depuis un MacOS:
```
diskutil list | grep external
diskutil unmountDisk disk4
sudo dd if=disk0.img of=/dev/rdisk4 bs=1m
```

## Déroulement du TP

### 1. Génération du Support PDF
Le support de TP est rédigé en [Markdown pandoc](https://daringfireball.net/projects/markdown/).
Exemple sur MacOS pour générer le PDF (nécessite pdflatex, ici dans basictex) :
```
brew install pandoc
brew install --cask basictex
pandoc TP_GIF_SSH_OpenVPN.md -o TP_GIF_SSH_OpenVPN.pdf --pdf-engine=/Library/TeX/texbin/pdflatex  -f markdown-implicit_figures
```

### 2. Configuration du Concentrateur VPN

Un poste sera désigné comme concentrateur VPN (serveur central). Cette machine jouera un rôle crucial dans l'infrastructure :

- Hébergement du serveur OpenVPN
- Gestion des tunnels GIF
- Serveur Web pour le monitoring
- Gestion des certificats et clés SSH

Pour configurer le concentrateur :
```
cd /tmp
sh preparation-server.sh
```

Ce script effectue automatiquement :
- La création de 20 comptes utilisateurs
- La génération des clés SSH pour chaque utilisateur
- La création des certificats OpenVPN
- La configuration du serveur OpenVPN
- La mise en place des tunnels GIF
- L'installation et configuration du serveur web de monitoring

### 3. Monitoring et Gestion des Routes

Un script de supervision doit être lancé en permanence sur le concentrateur pour :
- Gérer les conflits de routes entre OpenVPN et GIF
- Surveiller l'état des connexions VPN
- Permettre aux enseignants de suivre la progression des étudiants

Lancement du monitoring en début de TP :
```
cd /tmp
sh tunnels.sh
```

## Lancement du TP dans des VMs

La reproduction de ce TP sur des VMs ce réalise en lancant 4 VMs:

VM 1 (serveur siege) ---- VM 2 (concentrateur) ---- VM 3 (routeur VPN) --- VM 4 (poste de travail)

Exemple en utilisant le script QEMU du projet [BSDRP](https://bsdrp.net) sur un MacOS:

```
% brew install qemu
% cd ~/Downloadr
% wget https://raw.githubusercontent.com/ocochard/BSDRP/refs/heads/master/tools/BSDRP-lab-qemu.sh
% wget http://gugus69.free.fr/IUT/FreeBSD14-UEFI-iutstmalo.img.xz
% chmod +x BSDRP-lab-qemu.sh
% ./BSDRP-lab-qemu.sh -i FreeBSD14-UEFI-iutstmalo.img.xz -n 4
BSD Router Project: Qemu lab script
/opt/homebrew/bin/qemu-system-x86_64
Compressed image detected, uncompress it...
WARNING: Can't guests the CPU architecture of this image from the filename
Defaulting to x86_64
filename guests a serial image
Will use standard console as input/output
Guest VM configured without vga card
Starting 4 BSDRP VM full meshed
Starting a lab with 4 routers:
- 1 shared LAN between all routers and the host
- 0 LAN between all routers
- Full mesh ethernet point-to-point link between each routers

Router1 have the folllowing NIC:
vtnet0 connected to shared with host LAN, configure dhclient on this.
vtnet1 connected to Router2.
vtnet2 connected to Router3.
vtnet3 connected to Router4.
Connect to the console port of router 1 by telneting to localhost on port 8001
qemu-monitor is on port 9001 for this router (Ctrl-A + c)
Router2 have the folllowing NIC:
vtnet0 connected to shared with host LAN, configure dhclient on this.
vtnet1 connected to Router1.
vtnet2 connected to Router3.
vtnet3 connected to Router4.
Connect to the console port of router 2 by telneting to localhost on port 8002
qemu-monitor is on port 9002 for this router (Ctrl-A + c)
Router3 have the folllowing NIC:
vtnet0 connected to shared with host LAN, configure dhclient on this.
vtnet1 connected to Router1.
vtnet2 connected to Router2.
vtnet3 connected to Router4.
Connect to the console port of router 3 by telneting to localhost on port 8003
qemu-monitor is on port 9003 for this router (Ctrl-A + c)
Router4 have the folllowing NIC:
vtnet0 connected to shared with host LAN, configure dhclient on this.
vtnet1 connected to Router1.
vtnet2 connected to Router2.
vtnet3 connected to Router3.
Connect to the console port of router 4 by telneting to localhost on port 8004
qemu-monitor is on port 9004 for this router (Ctrl-A + c)
% telnet localhost 8001
Trying ::1...
Connected to localhost.
Escape character is '^]'.


FreeBSD/amd64 (routeur.univ-rennes1.fr) (ttyu0)

login: root
Password:
Mar 11 12:53:13 routeur login[1130]: ROOT LOGIN (root) ON ttyu0
Last login: Fri Mar  7 20:37:58 on ttyu0
FreeBSD 14.2-RELEASE (GENERIC) releng/14.2-n269506-c8918d6c7412

Bienvenu sur FreeBSD!

Le manuel FreeBSD: https://www.FreeBSD.org/handbook

Une copie du manuel est disponible localement, l'afficher par la commande suivante:
w3m /usr/local/share/doc/freebsd/en/books/handbook/index.html

root@routeur:~ #
```
