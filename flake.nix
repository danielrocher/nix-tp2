{
  description = "Gestion de parc informatique avec NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, deploy-rs, ... }:
  let
    system = "x86_64-linux";

    # Table centrale des machines
    machines = {
      webserver1 = { ip = "192.168.122.10"; hostname = "webserver1"; module = ./machines/webserver.nix; };
      webserver2 = { ip = "192.168.122.11"; hostname = "webserver2"; module = ./machines/webserver.nix; };
      client1   = { ip = "192.168.122.20"; hostname = "client1";   module = ./machines/client.nix; };
      client2   = { ip = "192.168.122.21"; hostname = "client2";   module = ./machines/client.nix; };
    };

    # Modules communs à toutes les machines
    commonModules = [
      disko.nixosModules.disko
      ./disks/standard.nix
      ./modules/common.nix
      ./modules/ssh.nix
      ./modules/network.nix
      ./modules/kvm-guest.nix
    ];

    # Fonction : créer une configuration NixOS
    mkHost = { module, ip, hostname, ... }: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { hostIp = ip; hostName = hostname; };
      modules = commonModules ++ [ module ];
    };

    # Fonction : créer un nœud deploy-rs
    mkNode = name: { ip, ... }: {
      hostname = ip;
      sshOpts  = [ "-p" "2222" ];
      profiles.system = {
        user    = "root";
        sshUser = "deploy";
        path    = deploy-rs.lib.${system}.activate.nixos
                    self.nixosConfigurations.${name};
      };
    };

  in {
    # Définition des machines
    nixosConfigurations = builtins.mapAttrs
      (_: mkHost) machines;

    # Cibles de déploiement (deploy-rs)
    deploy.nodes = builtins.mapAttrs
      (name: mkNode name) machines;

    # Vérification des déploiements
    checks.${system} = deploy-rs.lib.${system}.deployChecks self.deploy;
  };
}