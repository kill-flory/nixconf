# RGB-подсветка: OpenRGB как системная служба (ставит udev-правила и нужные модули i2c).
{ inputs, pkgs, ... }:

{
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd"; # Ryzen 5 7500F, платформа AM5
    # Пока в свежем nixpkgs плагины не грузятся — пакет из рабочего коммита
    package = inputs.nixpkgs-openrgb.legacyPackages.${pkgs.stdenv.hostPlatform.system}.openrgb-with-all-plugins;
  };
}