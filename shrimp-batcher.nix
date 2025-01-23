{ config, lib, pkgs, modulesPath, tfc-packages, ... }:

{
  # Import the base configuration
  imports = [ 
    ./base-configuration.nix 
    ./intel.nix
    tfc-packages.nixosModules.shrimp-batcher
  ];
  services.shrimp-batcher.enable = true;
  services.shrimp-batcher-hmi.enable = true;
  systemd.services.weston.enable = lib.mkForce true;


  # Please remember to declare hostname, it is used in the ISO name
  networking.hostName = lib.mkForce "shrimp-batcher";
  
#   # Override or add settings
#   users.users.tfc.password = "different-password";
  
  environment.systemPackages = lib.mkMerge [
    (with pkgs; [
      tfc-packages.packages.x86_64-linux.shrimp-batcher
    ])
  ];
}