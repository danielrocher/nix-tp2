# modules/common.nix
{ config, pkgs, ... }:
{
  # Fuseau horaire et locale
  time.timeZone                = "Europe/Paris";
  i18n.defaultLocale           = "fr_FR.UTF-8";
  console.keyMap               = "fr";

  # utilisateur avec droits d'administration
  users.users.admin = {
    isNormalUser  = true;
    extraGroups   = [ "wheel" ];
    # Clé SSH de l'administrateur
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG+J/W2BVkRcM1XyOUqwOMIjYPUAor+S4QdVkTbq5iGR admin@ci"
    ];
  };

  # Utilisateur de déploiement (deploy-rs)
  users.users.deploy = {
    isNormalUser  = true;
    extraGroups   = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJwNfV8prBpbQER2vReX5oUPlVL6saTN/jd2fh7l2kGD deploy-rs@ci"
    ];
  };

  # sudo sans mot de passe pour le déploiement automatisé
  security.sudo.extraRules = [{
    users   = [ "deploy" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Install vim avec conf. personnalisée
  programs.vim = {
    enable = true;
    defaultEditor = true;
    package = (pkgs.vim-full.override { }).customize {
      name = "vim";
      vimrcConfig.customRC = ''
        syntax on
        set vb
        set tabstop=1
        set softtabstop=4
        set shiftwidth=4
        set expandtab
        set mouse-=a
      '';
    };
  };

  # Paquets présents sur toutes les machines
  environment.systemPackages = with pkgs; [
    curl wget htop git
  ];

  # Mises à jour automatiques de sécurité
  system.autoUpgrade = {
    enable = true;
    flake  = "github:danielrocher/nix-tp2";
    allowReboot = false;   # reboot manuel
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # Garbage collection Nix automatique
  nix.gc = {
    automatic  = true;
    dates      = "weekly";
    options    = "--delete-older-than 20d";
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users         = [ "root" "deploy" ];
    # Clé publique de la machine de gestion
    trusted-public-keys   = [
      "parc-nix-1:Z5DDyChnPoHSVaqlcIPSm8UcXqqZyHV7XK3LGfN6xDg="
    ];
  };

  # Ne jamais changer system.stateVersion après l’installation initiale
  system.stateVersion = "25.11";
}