# Системная часть оболочки Panacea — то, что install.sh делал через sudo.
# Пакеты и пользовательские службы: modules/home-manager/panacea.nix
{ user, ... }:

{
  # Экран блокировки и хранилище паролей проверяют пароль через PAM-профиль
  # "swaylock". На Arch его кладёт пакет swaylock, на NixOS — только этот модуль.
  security.pam.services.swaylock = { };
  security.polkit.enable = true;

  # Bluetooth, питание, батарея
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Wi-Fi: Panacea ходит через iwd, NetworkManager работает поверх него.
  # Если Wi-Fi на этом ПК нет или что-то с сетью пойдёт не так — закомментируй обе строки.
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Диски и телефоны (MTP) в файловом менеджере оболочки
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Яркость монитора по DDC/CI (ddcutil): модуль i2c-dev + группа i2c
  hardware.i2c.enable = true;
  users.users.${user}.extraGroups = [ "i2c" ];

  # Формат времени en_GB (24 часа), как в install.sh; env.lua в hypr тоже его просит
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";
}
