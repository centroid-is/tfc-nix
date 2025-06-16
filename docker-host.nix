{ config, lib, pkgs, ... }:

{
  # Import the base configuration
  imports = [ 
    ./base-configuration.nix 
    ./intel.nix
  ];
  virtualisation.docker.enable = true;

  environment.systemPackages = lib.mkMerge [
    (with pkgs; [
      docker-compose
    ])
  ];

  users.users.tfc.extraGroups = [ "docker" ];

  # Please remember to declare hostname, it is used in the ISO name
  networking.hostName = lib.mkForce "docker-host";
}