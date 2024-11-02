{ config, pkgs, ... }:

let
  # Import the overlay
  myOverlay = import ./overlay.nix;
  # Apply the overlay to pkgs
  myPkgs = import <nixpkgs> { overlays = [ myOverlay ]; };
in
{
  imports = [
    # Import the minimal installation CD configuration
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
  ];

  ##### Kernel Configuration #####

  # Use the latest kernel packages
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enable full preemption in the kernel
  boot.kernel.preempt = "full";

  ##### Hardware Support #####

  # Update Intel CPU microcode
  hardware.cpu.intel.updateMicrocode = true;

  # Enable all firmware (useful for Intel hardware)
  hardware.enableAllFirmware = true;

  ##### Display Server #####

  # Enable the Weston Wayland compositor
  services.weston.enable = true;

  # Optionally, configure Weston to start automatically
  services.weston.autoStart = true;
  services.weston.user = "tfc";  # Ensure this user exists

  ##### WayVNC Configuration #####

  # Install WayVNC
  environment.systemPackages = with pkgs; [
    wayvnc
    myPkgs.flutter-embedded-linux
  ];

  # Set up WayVNC as a systemd service
  systemd.services.wayvnc = {
    description = "WayVNC Service";
    after = [ "graphical.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "tfc";  # Ensure this user exists
      ExecStart = "${pkgs.wayvnc}/bin/wayvnc --output=WAYLAND_DISPLAY";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  ##### User Configuration #####

  # Create a tfc user for auto-login
  users.users.tfc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "input" ];
    password = "";
  };

  # Enable auto-login for the tfc user
  services.getty.autologinUser = "tfc";

  ##### Flutter Application Service #####

  # Set up a systemd service to run the Flutter application
  systemd.services.flutter-app = {
    description = "Flutter Embedded Linux Application";
    after = [ "graphical.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "tfc";
      WorkingDirectory = "/home/tfc";  # Adjust as needed
      Environment = "LD_LIBRARY_PATH=${myPkgs.flutter-embedded-linux}/lib";
      ExecStart = "${myPkgs.flutter-embedded-linux}/lib/libflutter_elinux_wayland.so --bundle /home/tfc/flutter_app";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  ##### Networking (Optional) #####

  # Enable SSH for remote access
  services.openssh.enable = true;

  ##### Additional Configurations #####

  # Add any other configurations you need here.

}
