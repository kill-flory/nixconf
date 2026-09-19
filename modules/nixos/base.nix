# Базовая система: загрузчик, сеть, локаль, пользователь, nix.
{ pkgs, user, hostname, ... }:

{
  # --- Загрузчик ---
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Если после обновления ядра сломается nvidia — замени на pkgs.linuxPackages
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- Nix ---
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nixpkgs.config.allowUnfree = true;

  # --- Сеть, время, язык ---
  networking.hostName = hostname;
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "ru_RU.UTF-8";

  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };

  services.printing.enable = true;

  # Electron/Chromium-приложения (Discord и т.п.) нативно на Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # --- Пользователь ---
  # fish нужен как login-шелл: в нём живут алиасы и приглашение из Panacea
  programs.fish.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    description = "Gefest";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
  };

  # Только базовый минимум; пользовательские программы — в modules/home-manager/apps.nix
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];
}
