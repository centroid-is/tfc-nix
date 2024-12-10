## Build the ISO image

```bash
# nix build -L .#nixosConfigurations.<name of config to use>.config.system.build.isoImage
nix build -L .#nixosConfigurations.tfc-iso.config.system.build.isoImage
GITHUB_TOKEN=<your token> nix build -L .#nixosConfigurations.linescan-iso.config.system.build.isoImage --impure
ls -l ./result/iso
````

## Run QEMU with the ISO image

```bash
nix run -L .
````


### SSH into the VM

```bash
ssh -p 2222 tfc@localhost
```

### Rebuild the VM

```bash
rm disk1.qcow2
nix run -L .
```