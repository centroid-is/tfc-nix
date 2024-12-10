{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  inputs.disko.url = "github:nix-community/disko/master";
  inputs.disko.inputs.nixpkgs.follows = "nixpkgs";

  inputs.tfc-packages.url = "github:centroid-is/flakes?ref=v2024.12.2";

  outputs = inputs: {
    nixosConfigurations = {
      tfc = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          # Make tfc-packages available to configuration.nix
          inherit (inputs) tfc-packages;
        };
        modules = [
          inputs.disko.nixosModules.disko
          ./configuration.nix
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
      linescan = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit (inputs) tfc-packages;
        };
        modules = [
          inputs.disko.nixosModules.disko
          ./linescan.nix
        ];
      };
    };
    packages.x86_64-linux.default = let
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    in pkgs.writeShellApplication {
      name = "iso-test";
      runtimeInputs = with pkgs; [
        qemu-utils
        qemu_kvm
      ];
      text = ''
        disk1=disk1.qcow2
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
          -drive id=usbdisk,if=none,readonly=on,file="$(echo ${inputs.self.nixosConfigurations.iso.config.system.build.isoImage}/iso/*.iso)" \
          -netdev user,id=net0,hostfwd=tcp::2222-:22 \
          -device virtio-net-pci,netdev=net0 \
          -vnc :0
      '';
    };
  };
}
