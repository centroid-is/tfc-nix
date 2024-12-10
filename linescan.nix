{ config, lib, pkgs, modulesPath, tfc-packages, ... }:

{
  # Import the base configuration
  imports = [ 
    ./configuration.nix 
    tfc-packages.nixosModules.linescan-model
    tfc-packages.nixosModules.drangey
  ];
  services.drangey.enable = true;

  # Please remember to declare hostname, it is used in the ISO name
  networking.hostName = lib.mkForce "linescan";
  
#   # Override or add settings
#   users.users.tfc.password = "different-password";
  
  environment.systemPackages = lib.mkMerge [
    (with pkgs; [
      tfc-packages.packages.x86_64-linux.drangey
    ])
  ];
}