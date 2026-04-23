{ pkgs, hostName, hostIp, ... }:
{
  networking.hostName = hostName;

  networking.interfaces.enp1s0 = {
    ipv4.addresses = [{
      address      = hostIp;
      prefixLength = 24;
    }];
  };

  # Outils utiles pour les postes clients
  environment.systemPackages = with pkgs; [
    tmux
  ];

  # Utilisateur de travail
  users.users.operateur = {
    isNormalUser = true;
    description  = "Opérateur";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEzfpXevlBWBT95IWPgkzm3SIoZwc5Gdy63s5l3rEkOv operateur@ci"
    ];
    # mot de passe 'azerty' pour test (à changer)
    hashedPassword = "$6$xXNLzYMdLINaWoLZ$wNDn0oo2xwsQ1qEabRfo8lAOCKnbEin3IZGfQRZ7.V4zNR.tjNTEeW4W8ekdHoUXOTtKwFUXzOjzC/uJKjowr."; 
    # Shell avec configuration tmux automatique
    shell = pkgs.bash;
  };

  # Message d'accueil à la connexion SSH
  programs.bash.interactiveShellInit = ''
    echo "+-------------------------------+"
    echo "   Client Console - Parc NixOS"
    echo "+-------------------------------+"
    echo " Authorized users only. All activity may be monitored and reported."
  '';
}