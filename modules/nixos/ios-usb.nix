{ pkgs, ... }:

{
  # usbmuxd — демон, через который iPhone общается с компьютером по USB.
  # Без него любой инструмент (iLoader, libimobiledevice, Finder-замены)
  # просто не увидит устройство, даже если lsusb его показывает.
  services.usbmuxd.enable = true;

  environment.systemPackages = with pkgs; [
    libimobiledevice   # idevice_id, ideviceinfo, idevicepair — для диагностики
    ifuse              # монтирование iPhone как файловой системы, если понадобится
  ];
}
