{ config, lib, pkgs, ... }:

{
  # Import the base configuration
  imports = [ 
    ./base-configuration.nix 
    ./intel.nix
  ];

  # Please remember to declare hostname, it is used in the ISO name
  networking.hostName = lib.mkForce "tfc";
}