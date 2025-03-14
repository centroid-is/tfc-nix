{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  inputs.disko.url = "github:nix-community/disko/master";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.tfc-packages.url = "github:centroid-is/flakes?ref=22f6e1d8357f76c1912e5082d020c1cd2252bbe2";

  outputs = inputs: let
    # Helper function to create QEMU test script
    mkQemuTest = configName: let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      # Get the ISO configuration name
      isoConfig = "${configName}-iso";
    in pkgs.writeShellApplication {
      name = "${configName}-test";
      runtimeInputs = with pkgs; [
        qemu-utils
        qemu_kvm
      ];
      text = ''
        disk1=${configName}-disk.qcow2
        if [ ! -f $disk1 ]; then
          qemu-img create -f qcow2 $disk1 32G
        fi
        exec qemu-kvm \
          -boot c \
          -cpu host \
          -smp cores=2 \
          -M pc \
          -m 2G \
          -device virtio-balloon \
          -device virtio-rng-pci \
          -device nvme,serial=deadbeef,drive=nvm \
          -device usb-ehci \
          -device usb-storage,drive=usbdisk \
          -drive file=$disk1,format=qcow2,if=none,id=nvm,cache=unsafe,werror=report \
          -drive if=pflash,format=raw,unit=0,readonly=on,file=${pkgs.OVMF.firmware} \
          -drive id=usbdisk,if=none,readonly=on,file="$(echo ${inputs.self.nixosConfigurations.${isoConfig}.config.system.build.isoImage}/iso/*.iso)" \
          -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::5900-:5900 \
          -device virtio-net-pci,netdev=net0 
      '';
      # VNC SUPPORT, ENABLE IF NEEDED
    };
  in {
    nixosConfigurations = {
      tfc = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          # Make tfc-packages available to configuration.nix
          inherit (inputs) tfc-packages;
        };
        modules = [
          inputs.disko.nixosModules.disko
          ./base-configuration.nix
        ];
      };
      tfc-iso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          targetSystem = inputs.self.nixosConfigurations.tfc;
        };
        modules = [
          ./iso.nix
        ];
      };
      shrimp-batcher = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (inputs) tfc-packages;
        };
        modules = [
          inputs.disko.nixosModules.disko
          ./shrimp-batcher.nix
        ];
      };
      shrimp-batcher-iso = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          targetSystem = inputs.self.nixosConfigurations.shrimp-batcher;
        };
        modules = [
          ./iso.nix
        ];
      };
    };
    packages.x86_64-linux = {
      default = mkQemuTest "tfc";      # For testing TFC ISO
      shrimp-batcher = mkQemuTest "shrimp-batcher"; # For testing Shrimp Batcher ISO
    };
  };
}
