{ config, lib, pkgs, modulesPath, tfc-packages, ... }:

{
  # Import the base configuration
  imports = [ 
    ./base-configuration.nix 
    ./amd.nix
    tfc-packages.nixosModules.linescan-model
    tfc-packages.nixosModules.drangey
  ];
  services.drangey.enable = true;

  # Please remember to declare hostname, it is used in the ISO name
  networking.hostName = lib.mkForce "linescan";
  
  # Add debug kernel parameters
  boot.kernelParams = [
    "loglevel=7"                    # Kernel debug messages
    "systemd.log_level=debug"       # Systemd debug logging
    "systemd.log_target=console"    # Log to console
    "udev.log_priority=debug"       # udev debug logging
  ];
#   # Override or add settings
#   users.users.tfc.password = "different-password";
  
  environment.systemPackages = lib.mkMerge [
    (with pkgs; [
      tfc-packages.packages.x86_64-linux.drangey
    ])
  ];
}