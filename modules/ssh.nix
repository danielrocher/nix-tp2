{ ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      AllowTcpForwarding = false;
      AllowAgentForwarding = false;
      X11Forwarding = false;
      PrintLastLog = true;
    };
    ports = [ 2222 ];
  };

  # Firewall : autoriser SSH
  networking.firewall.allowedTCPPorts = [ 2222 ];

  # Afficher des informations supplémentaires lors de la connexion
  environment.etc."profile.d/motd.sh".source = pkgs.writeShellScript "motd.sh" ''
    uname -snrvm
    uptime -p

  '';

}