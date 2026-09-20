# GPU: NVIDIA RTX 4060 (проприетарный драйвер).
{ config, ... }:

{
  # Нужно и для Wayland — так подтягивается драйвер nvidia
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam / Wine
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Одна видеокарта, поэтому можно задать глобально (для GNOME и Hyprland сразу)
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
