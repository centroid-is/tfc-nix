# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, modulesPath, tfc-packages, ... }:

{
  imports = [
    #(modulesPath + "/profiles/all-hardware.nix")
    ./disko.nix
    # ./intel.nix # CAN BE CHANGED TO amd.nix
    # tfc-packages.nixosModules.tfc-hmi
  ];
  # services.tfc-hmi.enable = true;

  boot.kernelPackages = pkgs.linuxPackages-rt;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.timeout = 0;

  networking.hostName = "tfc"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "Atlantic/Reykjavik";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console =  {
    earlySetup = true;
    font = "ter-v16n";
    packages = [ pkgs.terminus_font ];
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.tfc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Enable ‘sudo’ for the user. And allow networkmanager access.
    password = "tfc";
    shell = "${pkgs.fish}/bin/fish";
    packages = with pkgs; [
      tree
      # tfc-packages.packages.x86_64-linux.tfc-hmi
    ];
  };
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      # OpenGL Drivers
      mesa

      # Vulkan Drivers
      vulkan-loader
    ];
  };
  # hardware.videoDrivers = [ "intel" ]; # this does not work, this option is non existent


  users.users.root.password = "root";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    libinput
    seatd
    weston
    dbus
    plymouth
    systemd
    rustc
    cargo
    bash-completion
  ];

  services.zerotierone = {
    enable = true;
    #   joinNetworks = [
    # "6465f4ee45356976"
    # "71e441cc137b93c8"
    # ];
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Automatically log in at the virtual consoles.
  services.getty.autologinUser = "tfc";

  #### WESTON ####

  # Allow VNC connections on port 5900
  networking.firewall.allowedTCPPorts = [ 22 5900 ];

  systemd.services.create-keys = {
    description = "Create TLS keys and certificates on startup";

    # Only run the service if /var/tfc/certs/tls.crt does NOT exist
    unitConfig.ConditionPathExists = "!/var/tfc/certs/tls.crt";

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      Group = "root";

      # Define the sequence of commands to execute
      ExecStart = [
        "mkdir -p /var/tfc/certs"
        "/usr/bin/openssl genrsa -out /var/tfc/certs/tls.key 2048"
        "/usr/bin/openssl req -new -key /var/tfc/certs/tls.key -out /var/tfc/certs/tls.csr -subj '/C=IS/ST=Höfuðborgar Svæðið/L=Reykjavik/O=Centroid'"
        "/usr/bin/openssl x509 -req -days 365000 -signkey /var/tfc/certs/tls.key -in /var/tfc/certs/tls.csr -out /var/tfc/certs/tls.crt"
        "chown -R tfc:users /var/tfc/"
      ];
    };

    # Ensure the service is part of the graphical.target
    wantedBy = [ "graphical.target" ];
  };

  # create the directory /etc/tfc during build
  environment.etc."tfc".source = "/var/tfc";

  # Add the weston.ini file to /etc/xdg/weston/weston.ini
  environment.etc."xdg/weston/weston.ini".text = ''
    [core]
    modules=screen-share.so
    backend=drm
    shell=kiosk-shell.so
    require-input=false
    idle-time=0
    renderer=gl

    [shell]
    background-image=none
    clock-format=none
    panel-position=none
    locking=false
    num-workspaces=1
    allow_zap=false
    close-animation=none
    startup-animation=none
    focus-animation=none

    [vnc]
    refresh-rate=60
    # tls-key=/var/tfc/certs/tls.key
    # tls-cert=/var/tfc/certs/tls.crt

    [screen-share]
    command=weston --backend=vnc-backend.so --vnc-tls-cert=/var/tfc/certs/tls.crt --vnc-tls-key=/var/tfc/certs/tls.key --shell=kiosk-shell.so --no-config --debug
    start-on-startup=true

    [output]
    name=vnc
    resizeable=false
  '';

  #   # Define the weston.socket
  # systemd.sockets."weston.socket" = {
  #   # Description of the socket
  #   description = "Weston socket";

  #   # Ensure the /run directory is mounted
  #   requiresMountsFor = [ "/run" ];

  #   # Configure the socket to listen on /run/wayland-0
  #   # listenStream = "/run/wayland-0";

  #   # Set the socket permissions
  #   socketMode = "0775";

  #   # Define the user and group for the socket
  #   socketUser = "weston";
  #   socketGroup = "wayland";

  #   # Remove the socket file when the service stops
  #   # removeOnStop = true;

  #   # Specify that this socket should be wanted by the sockets target
  #   wantedBy = [ "sockets.target" ];
  # };

  # Define the Weston systemd service
  systemd.targets."graphical.target".enable = true;
  systemd.services.weston = {
    description = "Weston, a Wayland compositor, as a system service";
    documentation = [
      "man:weston(1)"
      "man:weston.ini(5)"
      "http://wayland.freedesktop.org/"
    ];

    # Service Dependencies
    requires = [ "systemd-user-sessions.service" ];
    after = [ "systemd-user-sessions.service" "dbus.socket" ];
    wants = [ "dbus.socket" ];

    # Ensure the service starts before the graphical target
    before = [ "graphical.target" ];

    # Condition to ensure /dev/tty0 exists
    unitConfig.ConditionPathExists = "/dev/tty0";

    # Service Configuration
    serviceConfig = {
      Type = "notify";
      Environment = [ 
        "WAYLAND_DISPLAY=wayland-1" # todo this does not respond to changes
      ];
      ExecStart = "${pkgs.weston}/bin/weston --modules=systemd-notify.so";
      User = "tfc";
      Group = "users";
      WorkingDirectory = "/home/tfc";
      PAMName = "weston-autologin";
      Restart = "always";
      RestartSec = "3";

      # Optional Watchdog settings (uncomment if needed)
      # TimeoutStartSec = "60";
      # WatchdogSec = "20";

      # TTY Configuration
      TTYPath = "/dev/tty7";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";

      # Standard IO Configuration
      StandardInput = "tty-fail";
      StandardOutput = "journal";
      StandardError = "journal";

      # Utmp Configuration
      UtmpIdentifier = "tty7";
      UtmpMode = "user";
    };

    wantedBy = [ "default.target" ];
  };

  systemd.services.weston.enable = false; # override from explicit configuration like linescan.nix

  security.pam.services."weston-autologin".text = ''
    auth       include    login
    account    include    login
    session    include    login
  '';

  #### END WESTON ####

  services.dbus.packages = [
    (pkgs.writeTextFile {
      name = "dbus-centroid-conf";
      destination = "/share/dbus-1/system.d/is.centroid.conf";
      text = ''
        <!DOCTYPE busconfig PUBLIC
        "-//freedesktop//DTD D-Bus Bus Configuration 1.0//EN"
        "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
        <busconfig>
        <policy context="default">
          <allow own_prefix="is.centroid"/>
          <allow send_destination_prefix="is.centroid"/>
        </policy>
        </busconfig>
      '';
    })
  ];

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.05"; # Did you read the comment?

  # Enable flakes
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };
}
