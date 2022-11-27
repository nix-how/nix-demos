{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forSystems = systems: f:
        nixpkgs.lib.genAttrs systems
        (system: f system nixpkgs.legacyPackages.${system});
      forAllSystems = forSystems supportedSystems;
    in
    {
      bundlers = (forAllSystems (system: pkgs: {
        runtimeReport = drv: import ./bundlers/runtimeReport { inherit drv pkgs; };
      }));
    };
}
