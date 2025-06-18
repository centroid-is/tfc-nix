{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    ./intel.nix
    ./disko.nix
  ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 0;

  # Networking
  networking.hostName = "docker-host";
  networking.networkmanager.enable = true;

  # Time zone
  time.timeZone = "Atlantic/Reykjavik";

  # Internationalisation
  i18n.defaultLocale = "en_US.UTF-8";

  # User configuration
  users.users.tfc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    password = "tfc";
    shell = "${pkgs.fish}/bin/fish";
    packages = with pkgs; [
      tree
    ];
  };

  users.users.root.password = "root";

  # System packages
  environment.systemPackages = lib.mkMerge [
    (with pkgs; [
      git
      vim
      dbus
      systemd
      bash-completion
      docker-compose
    ])
  ];

  # Hardware configuration
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  hardware.graphics = {
    enable = true;
  };

  # ZeroTier configuration
  services.zerotierone = {
    enable = true;
  };

  # SSH configuration
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.Macs = [
    "hmac-sha2-512"
    "hmac-sha2-256"
    "umac-128@openssh.com"
  ];

  # Auto login
  services.getty.autologinUser = "tfc";

  # Docker configuration
  virtualisation.docker.enable = true;

  # System version
  system.stateVersion = "25.05";

  # Nix settings
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };
}