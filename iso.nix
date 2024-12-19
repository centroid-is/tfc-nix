{ config, pkgs, lib, modulesPath, targetSystem, ... }:
let
  installer = pkgs.writeShellApplication {
    name = "installer";
    runtimeInputs = with pkgs; [
      dosfstools
      e2fsprogs
      gawk
      nixos-install-tools
      util-linux
      config.nix.package
      evtest
    ];
    text = ''
      set -euo pipefail

      echo "Setting up disks..."
      for i in $(lsblk -pln -o NAME,TYPE | grep disk | awk '{ print $1 }'); do
        if [[ "$i" == "/dev/fd0" ]]; then
          echo "$i is a floppy, skipping..."
          continue
        fi
        if grep -ql "^$i" <(mount); then
          echo "$i is in use, skipping..."
        else
          DEVICE_MAIN="$i"
          break
        fi
      done
      if [[ -z "$DEVICE_MAIN" ]]; then
        echo "ERROR: No usable disk found on this machine!"
        exit 1
      else
        echo "Found $DEVICE_MAIN, erasing..."
      fi

      DISKO_DEVICE_MAIN=''${DEVICE_MAIN#"/dev/"} ${targetSystem.config.system.build.diskoScript} 2> /dev/null

      echo "Copying configuration files..."
      find / -name "base-configuration.nix"
      ls -alh /iso/nixos
      mkdir -p /mnt/etc/nixos/
      cp -r /iso/nixos/* /mnt/etc/nixos/

      echo "Installing the system..."
      nixos-install --no-channel-copy --no-root-password --option substituters "" --system ${targetSystem.config.system.build.toplevel}

      echo "Installation complete!"
      echo "Please:"
      echo "Be quick and remove the USB installation drive, will reboot in 10 seconds"
      # echo "1. Remove the USB installation drive"
      # echo "2. Tap screen, click mouse, or press any key to reboot"
      echo ""

      # # Monitor all input devices for any event
      # for dev in /dev/input/event*; do
      #   evtest --grab "$dev" | grep -m 1 "type.*\(EV_KEY\|EV_ABS\)" &
      # done
      
      # # Wait for any input event
      # wait -n
      
      # # Kill all remaining background processes
      # kill "$(jobs -p)" 2>/dev/null || true

      sleep 10
      echo "Rebooting..."
      reboot
    '';
  };
  installerFailsafe = pkgs.writeShellScript "failsafe" ''
    ${lib.getExe installer} || echo "ERROR: Installation failure!"
    sleep 3600
  '';
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  boot.kernelParams = [ "systemd.unit=getty.target" ];

  console =  {
    earlySetup = true;
    font = "ter-v16n";
    packages = [ pkgs.terminus_font ];
  };

  # BIG TODO hostname is not the correct mechanism to propagate filename
  isoImage.isoName = "${targetSystem.config.networking.hostName}-${config.isoImage.isoBaseName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;
  isoImage.squashfsCompression = "zstd -Xcompression-level 15"; # xz takes forever
  # ONE important note, the files root location is /iso, not /
  isoImage.contents = [
    # BIG TODO hostname is not the correct mechanism to propagate filename
    { source = ./${targetSystem.config.networking.hostName}.nix; target = "/nixos/configuration.nix"; }
    { source = ./base-configuration.nix; target = "/nixos/base-configuration.nix"; }
    { source = ./disko.nix;         target = "/nixos/disko.nix"; }
    { source = ./flake.nix;         target = "/nixos/flake.nix"; }
    { source = ./flake.lock;        target = "/nixos/flake.lock"; }
    { source = ./intel.nix;         target = "/nixos/intel.nix"; }
  ];

  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      ExecStart = [ "" installerFailsafe ];
      Restart = "no";
      StandardInput = "null";
    };
  };

  system.stateVersion = "24.05";
}
