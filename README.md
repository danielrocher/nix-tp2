
## Liens utiles

 - https://search.nixos.org/
 - https://blog.stephane-robert.info/docs/admin-serveurs/linux/references-complementaires/nix/

## Outils NIX utilisés dans le TP

- **disko** : outil pour partitionner
- **deploy-rs** : outil de déploiement sur machines distantes

## Préparation

Installer un poste d'administration sous nixOS 25.11. À partir de la machine hôte :
```bash
wget https://channels.nixos.org/nixos-25.11/latest-nixos-graphical-x86_64-linux.iso

virt-install --name nixos-admin \
  --memory 8192 --vcpus 4 \
  --disk size=80 \
  --cdrom latest-nixos-graphical-x86_64-linux.iso \
  --os-variant nixos-unstable \
  --network network=default,model=virtio \
  --graphics spice,listen=127.0.0.1 \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readonly=yes,loader.type=pflash,loader.secure=no \
  --noautoconsole
```

Une fois l'installation terminée, dans la VM d'administration :
```bash
# Générer une paire de clés SSH pour l'administration
ssh-keygen -o -a 256 -t ed25519 -f ~/.ssh/id_ed25519 -C "admin@ci"

# Générer une paire de clés SSH qui servira pour le déploiement (deploy-rs)
ssh-keygen -o -a 256 -t ed25519 -f ~/.ssh/id_ed25519_deploy -C "deploy-rs@ci"

# reporter les deux clés publiques dans le fichier  modules/common.nix
# cat ~/.ssh/id_ed25519.pub ~/.ssh/id_ed25519_deploy.pub

# Générer une paire de clés de signature sur la machine de gestion
sudo nix-store --generate-binary-cache-key parc-nix-1 \
  /etc/nix/signing-key.sec \
  /etc/nix/signing-key.pub

cat /etc/nix/signing-key.pub
# clé publique à reporter dans la configuration modules/common.nix
```


## Déploiement des machines

```bash
# téléchargement de l'ISO minimal
wget https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-x86_64-linux.iso

# au moment de l'installation, ne pas limiter la RAM car on est en "liveCD"
virt-install --name client1 \
  --memory 8192 --vcpus 4 \
  --disk size=40 \
  --cdrom latest-nixos-minimal-x86_64-linux.iso \
  --os-variant nixos-unstable \
  --network network=default,model=virtio \
  --graphics spice,listen=127.0.0.1 \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readonly=yes,loader.type=pflash,loader.secure=no \
  --noautoconsole

virt-install --name webserver1 \
  --memory 8192 --vcpus 4 \
  --disk size=40 \
  --cdrom latest-nixos-minimal-x86_64-linux.iso \
  --os-variant nixos-unstable \
  --network network=default,model=virtio \
  --graphics spice,listen=127.0.0.1 \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.fd,loader.readonly=yes,loader.type=pflash,loader.secure=no \
  --noautoconsole
```


Configurer le premier poste client (client1) :
```bash
sudo loadkeys fr
passwd # définir un mot de passe temporaire pour installation

# Depuis mon poste
ssh nixos@192.168.222.xxx

sudo mkdir -p /root/.config/nix/
echo "experimental-features = nix-command flakes" | sudo tee /root/.config/nix/nix.conf

# utilisation de disko. Partitionnement et montage
sudo nix run github:nix-community/disko/latest -- \
  --mode disko \
  --flake github:danielrocher/nix-tp2#client1

# Vérification
lsblk --fs /dev/vda
mount | grep vda

# Installation de l'OS
sudo nixos-install \
  --flake github:danielrocher/nix-tp2#client1 \
  --no-root-passwd

# Vérification
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# reboot et connexion avec nouveau compte
sudo reboot
ssh -p 2222 admin@192.168.222.20
...
```

Pour serveur web (webserver1) :
```bash
#idem que précèdent, en adaptant url
...
sudo nix run github:nix-community/disko/latest -- \
  --mode disko \
  --flake github:danielrocher/nix-tp2#webserver1
...
sudo nixos-install \
  --flake github:danielrocher/nix-tp2#webserver1 \
  --no-root-passwd
...
ssh -p 2222 admin@192.168.222.10

# Vérification
curl 192.168.222.10
```

## deploy-rs

À partir du poste d'administration :
```bash
# check before
nix run github:serokell/deploy-rs -- --dry-activate github:danielrocher/nix-tp2#webserver1
# deploie sur la machine webserver1, à partir du depot git
nix run github:serokell/deploy-rs -- github:danielrocher/nix-tp2#webserver1
# ou bien à partir d'un chemin local
nix run github:serokell/deploy-rs -- /mnt/partage_vm/tp2/#webserver1
# à partir de git sur une branche particulier (develop)
nix run github:serokell/deploy-rs -- github:danielrocher/nix-tp2/develop#webserver1
```

## Extra

### Créer flake.lock

Permet de figer les paquets à une version

```bash
git clone git@github.com:danielrocher/nix-tp2.git
nix flake update
git add flake.lock
git commit -a -m "feat: added flake.lock"
```

### Vider le cache
```bash
rm -rf ~/.cache/nix
sudo rm -rf /root/.cache/nix
```

### Simuler un serveur git avec python

```bash
git clone --bare tp2/ parc-nix.git
cd parc-nix.git/
git fetch origin main:main
git update-server-info
cd ..
python3 -m http.server -b 192.168.222.1 8000
```
