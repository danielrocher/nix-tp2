{ ... }:
{
  # Désactiver NetworkManager et DHCP global
  networking = {
    useDHCP              = false;
    useNetworkd          = false;
    defaultGateway       = "192.168.122.1";

    nameservers = [ "192.168.122.1" ];

    # Firewall de base
    firewall = {
      enable          = true;
      allowPing       = true;
    };
  };
}