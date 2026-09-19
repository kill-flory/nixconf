# Пользовательская часть Hyprland + зависимости оболочки Panacea (Quickshell).
{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # Quickshell из флейка
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Qt6 QML-модули для виджетов Quickshell
    qt6.qtdeclarative
    qt6.qtmultimedia
    qt6.qtsvg
    qt6.qt5compat

    # Обои, ночной режим, блокировка
    hyprpaper
    hyprsunset
    swaylock
    mpvpaper

    # Буфер обмена, скриншоты, запись экрана
    wl-clipboard
    cliphist
    grim
    slurp
    wf-recorder
    ffmpeg
    wtype

    # Яркость, медиа, визуализатор
    brightnessctl
    ddcutil
    playerctl
    cava

    # Диски и прочее, что дёргает Panacea
    udiskie
    gvfs
    jq
    openssl
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland и портал ставит системный модуль (modules/nixos/hyprland.nix);
    # null — чтобы не было двух разных версий
    package = null;
    portalPackage = null;

    settings = {
      monitor = ",preferred,auto,1";

      exec-once = [
        "udiskie &"
        "quickshell -c panacea &"
      ];

      # LIBVA_DRIVER_NAME и __GLX_VENDOR_LIBRARY_NAME уже заданы глобально в nvidia.nix
      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
      ];
    };
  };
}
