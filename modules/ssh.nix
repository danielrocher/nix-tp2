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
}