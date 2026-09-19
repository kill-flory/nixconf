# Конфигурация машины "nixos": только список подключаемых модулей.
# Сами настройки живут в modules/nixos/.
{ ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../../modules/nixos/base.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/gnome.nix
    ../../modules/nixos/hyprland.nix
    ../../modules/nixos/gaming.nix
  ];

  system.stateVersion = "26.05";
}
