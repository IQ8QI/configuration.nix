{ config, pkgs, ... }:

{
# Partitioning
  fileSystems."/boot" = {
    device = "/dev/sda1";
    fsType = "vfat";
    size = "1G";
  };
  fileSystems."/" = {
    device = "/dev/sda2";
    fsType = "btrfs";
    size = "60G";
  };
  fileSystems."swap" = {
    device = "/dev/sda3";
    fsType = "swap";
    size = "8G";
  };
  fileSystems."/home" = {
    device = "/dev/sda4";
    fsType = "btrfs";
  };

  # Timeshift configuration for /home
  services.timeshift = {
    enable = true;
    btrfsSubvolume = "/home";
    numDailySnapshots = 7;
    numWeeklySnapshots = 3;
    numMonthlySnapshots = 3;
    snapshotSize = "2G";
    snapshotDevice = "/dev/sda4";
  };

  # Set GRUB as the bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

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
    timeshift
    linux-firmware
    # Security packages
    clamav
    ossec-hids
    rkhunter
    lynis
  ];

  # Set GNOME as the default desktop environment
  services.xserver.desktopManager.gnome.enable = true;

  # Hardening options
  # Enable automatic updates at every computer shutdown
  system.autoUpgrade.enable = true;

  # Enable and configure UFW
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [];

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

  # Disable ssh
  services.openssh.enable = false;

  # Define a systemd service to update clamav database at evey startup
  systemd.services.update_clamav_database = {
    description = "Update clamav database at boot";
    serviceConfig.ExecStart = "freshclam";
    wantedBy = [ "multi-user.target" ];
  };

  # Add the service to the `wants` list for `multi-user.target`
  systemd.targets["multi-user.target"].wantedBy = ["update_clam"];

  # Define a systemd service to run ClamAV scan
  systemd.services.clamav-scan = {
    description = "Run ClamAV scan of / directory";
    serviceConfig.ExecStart = "${pkgs.clamav}/bin/clamscan -r /";
    wantedBy = [ "multi-user.target" ];
  };

  # Define a systemd timer to schedule the service
  systemd.timers.clamav-scan = {
    description = "Schedule ClamAV scan every 4th day";
    timerConfig.OnCalendar = "*-*-* 0:00:00";  # Set the specific time (midnight)
    timerConfig.OnUnitActiveSec = "4d";         # Run every 4 days
  };

}
