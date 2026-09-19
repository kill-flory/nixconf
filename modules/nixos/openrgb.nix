# RGB-подсветка: OpenRGB как системная служба (ставит udev-правила и нужные модули i2c).
{ pkgs, ... }:

{
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd"; # Ryzen 5 7500F, платформа AM5
    package = pkgs.openrgb-with-all-plugins;
  };
}