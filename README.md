# TP VPN

TP sur les technos VPN pour classes de licences professionnelles: ASUR (Administration et Sécurité des Réseaux) et RIMS (Réseaux Informatiques Mobilité Sécurité).

## Creation de l'image disque FreeBSD

Processus de création de l'image à partir d'un poste FreeBSD:
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

Pour les paramètres d'installation d'un FreeBSD sur cette image:
* Console type: par défaut (VT100)
* Install
* Continue with default keymap: La configuration du clavier français se fera plus tard
* Hostname: routeur.univ-rennes1.fra
* Choix des packages: Désélectionner kernel-dbg et lib32
* Partitionning: Manual, Create, MBR (DOS partitions), Create, selectionner la nouvelle partition s1, Create, Mountpoint: /, Finish, Commit
* Mot de passe root: stmalo
* Configurer le réseau pour l'installation des packages et scripts
* Configurer la timezone
* Services: Désactiver SSHD et dumpdev
* Sécurité: laisser par défaut
* Ajout d'utilisateur: non
* Exit (Apply configuration)
* Lancer un shell: NO
* Reboot ou LiveCD: LiveCD

```
tunefs -L rootfs /dev/vtbd0s1a
reboot
```

Redémarrer le système à la fin, puis se connecter en root sur la machine et lancer le script de préparation du master:
* Modification du /etc/fstab pour utiliser le label UFS (/dev/ufs/rootfs) au lieu des noms des disques physique pour permettre de booter depuis une clé USB ensuite
* Personnalisation du système (clavier français)
* Création du compte etudiant/iut
* Installation des scripts serveur et tunnel

```
cd /tmp
fetch --no-verify-peer https://raw.githubusercontent.com/ocochard/TP-VPN/master/scripts/preparation-master.sh
sh preparation-master.sh
shutdown -p
```

## Transfert de l'image disque sur une clé USB (2Go)
Une fois terminé, l'image disque peux être transférée sur clé USB avec un simple dd (ou Win32 Disk Imager sous windows).
```
dd if=/home/olivier/VMs/iutstmalo/disk0.img of=/dev/da0 bs=512k
```

## Génération du PDF de support de TP
Pour la converstion du document latex en pdf, depuis un FreeBSD (pkg install tex-formats tex-xetex) ou Mac (après avoir installé MacTex) il faut executer 2 fois xelatex pour la génération de la table des matières):
```
xelatex TP_GIF_SSH_OpenVPN.tex
xelatex TP_GIF_SSH_OpenVPN.tex
```
