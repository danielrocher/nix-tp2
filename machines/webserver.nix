{ pkgs, hostName, hostIp, ... }:
{
  networking.hostName = hostName;

  networking.interfaces.enp1s0 = {
    ipv4.addresses = [{
      address      = hostIp;
      prefixLength = 24;
    }];
  };

  # Nginx
  services.nginx = {
    enable = true;

    recommendedTlsSettings      = true;
    recommendedOptimisation     = true;
    recommendedGzipSettings     = true;
    recommendedProxySettings    = true;

    virtualHosts."mon-site.local" = {
      root       = "/var/www/mon-site";
      extraConfig = ''
        index index.html;
        try_files $uri $uri/ =404;
      '';
    };
  };

  # Contenu web géré par Nix
  environment.etc."www/mon-site/index.html" = {
    text = ''
      <!DOCTYPE html>
      <html><body>
        <h1>Serveur géré par NixOS</h1>
        <p>Déployé de façon déclarative.</p>
      </body></html>
    '';
  };

  # Lien symbolique vers le contenu
  systemd.tmpfiles.rules = [
    "L+ /var/www/mon-site - - - - /etc/www/mon-site"
  ];

  # Firewall : HTTP + HTTPS
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # logrotate
  services.logrotate.enable = true;
}