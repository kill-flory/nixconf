# RGB-подсветка: OpenRGB как системная служба (ставит udev-правила и нужные модули i2c).
{ ... }:

{
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd"; # Ryzen 5 7500F, платформа AM5
  };
}