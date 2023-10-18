{ config, pkgs, ... }:

{
  # Set GRUB as the bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sdX"; # Replace 'sdX' with your actual disk device

  # Set system language and fonts to Polish
  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "pl";
    defaultLocale = "pl_PL.UTF-8";
  };

  # Create user "bkonecki" with sudo privileges and disable root user
  users.users.bkonecki = {
    isNormalUser = true;
    home = "/home/bkonecki";
    createHome = true;
    description = "Bartłomiej Konecki";
    hashedPassword = ""; # Leave this empty to require a password to be set upon first login
    initialPassword = "";
    openssh.authorizedKeys.keys = [ ]; # If you want to set SSH keys, add them here
    extraGroups = [ "wheel" ]; # Add the user to the "wheel" group for sudo privileges
  };
  users.users.root = {
    isNormalUser = false;
    home = "/var/empty";
    createHome = false;
  };

  # Install packages
  environment.systemPackages = with pkgs; [
    gnome3
    gnome3.gdm
    libreoffice
    gufw
    ufw
    librewolf
    firefox
    steam
    vim
    git
    thunderbird
    linuxKernel.kernels.linux_hardened
  ];

  # Set GNOME as the default desktop environment
  services.xserver.desktopManager.gnome.enable = true;

  # Hardening options
  # Enable automatic updates at every computer shutdown
  system.autoUpgrade.enable = true;

  # Enable and configure UFW
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ]; # Add other allowed ports as needed

  # Password policy
  security.pam.services."common-password".enable = true;
  security.pam.services."common-password".password-requisite = "pam_pwquality.so retry=3";
  security.pam.services."common-password".password requisite = "pam_pwquality.so retry=3";

  # Configure UFW for safe home settings
  services.ufw = {
    enable = true;
    defaultInputPolicy = "DROP"; # Default to deny incoming traffic
    rules = [];
  };

  # SSH Hardening for user "bkonecki"
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;
  services.openssh.extraConfig = ''
    AllowUsers bkonecki
    PermitRootLogin no
    PasswordAuthentication yes
  '';
}
