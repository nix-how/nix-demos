{
  description = "NixOS in MicroVMs";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [ "https://microvm.cachix.org" "https://poetry2nix.cachix.org" "https://matthewcroughan.cachix.org" ];
    extra-trusted-public-keys = [ "microvm.cachix.org-1:oXnBc6hRE3eX5rSYdRyMYXnfzcCxC7yKPTbZXALsqys=" "poetry2nix.cachix.org-1:2EWcWDlH12X9H76hfi5KlVtHgOtLa1Xeb7KjTjaV/R8=" "matthewcroughan.cachix.org-1:fON2C9BdzJlp1qPan4t5AF0xlnx8sB0ghZf8VDo7+e8=" ];
  };

  outputs = { self, nixpkgs, microvm }:
    let
      system = "x86_64-linux";
    in {
      defaultPackage.${system} = self.packages.${system}.microvm;

      packages.${system}.microvm =
        let
          inherit (self.nixosConfigurations.microvm) config;
          hypervisor = "qemu";
        in config.microvm.runner.${hypervisor};

      nixosConfigurations.microvm = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          microvm.nixosModules.microvm
          ({ config, pkgs, ... }: {
            systemd.services.initialConfig = {
              description = "Copy configuration into microvm";
              wantedBy = [ "multi-user.target" ];
              unitConfig.ConditionPathExists = "!/root/flake.nix";
              serviceConfig.Type = "oneshot";
              script = ''
                mkdir -p /etc/nixos
                cp --no-preserve=mode ${./flake.nix} /etc/nixos/flake.nix
                cp --no-preserve=mode ${./flake.lock} /etc/nixos/flake.lock
                cp --no-preserve=mode ${./configuration.nix} /etc/nixos/configuration.nix
              '';
            };
            networking.hostName = "microvm";
            users.users.root.password = "";
            nix = {
              nixPath = [ "nixpkgs=${nixpkgs}" ];
              extraOptions = ''
                experimental-features = nix-command flakes
                accept-flake-config = true
              '';
            };
            environment.systemPackages = with pkgs; [ magic-wormhole bore-cli ];
            services.logind.extraConfig = "RuntimeDirectorySize=2G";
            services.mingetty.autologinUser = "root";
            microvm = {
              vcpu = 4;
              interfaces = [ {
                type = "user";
                id = "microvm-a1";
                mac = "02:00:00:00:00:01";
              } ];
              balloonMem = 4096;
              volumes = [
                {
                  mountPoint = "/";
                  image = "rootfs.img";
                  size = 10240;
                }
                {
                  image = "nix-store-overlay.img";
                  mountPoint = config.microvm.writableStoreOverlay;
                  size = 10240;
                }
              ];
	      writableStoreOverlay = "/nix/.rw-store";
              shares = [ {
                # use "virtiofs" for MicroVMs that are started by systemd
                proto = "9p";
                tag = "ro-store";
                # a host's /nix/store will be picked up so that the
                # size of the /dev/vda can be reduced.
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
              } ];
              socket = "control.socket";
              # relevant for delarative MicroVM management
              hypervisor = "qemu";
            };
          })
        ];
      };
    };
}
