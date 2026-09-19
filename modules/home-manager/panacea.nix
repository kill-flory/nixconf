# Оболочка Panacea: пакеты, Quickshell, голос-в-текст, курсор.
# Конфиги (~/.config/panacea, foot, fish...) сюда НЕ входят: оболочка сама пишет в них
# настройки, поэтому они копируются скриптом scripts/panacea-sync.sh, а не ссылками из /nix/store.
# ~/.config/hypr не управляется Nix вообще.
{ pkgs, lib, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Quickshell на NixOS сам не знает, где лежат QML-модули Qt (Multimedia, Controls, Effects, Shapes).
  # Оборачиваем его и подсовываем пути. Версии Qt те же, что у nixpkgs, — quickshell следует за ним.
  qtModules = with pkgs.qt6; [ qtdeclarative qtmultimedia qtsvg qt5compat ];
  quickshellPanacea = pkgs.symlinkJoin {
    name = "quickshell-panacea";
    paths = [ inputs.quickshell.packages.${system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/*; do
        wrapProgram "$bin" \
          --prefix QML2_IMPORT_PATH : "${lib.makeSearchPath "lib/qt-6/qml" qtModules}" \
          --prefix QT_PLUGIN_PATH : "${lib.makeSearchPath "lib/qt-6/plugins" qtModules}"
      done
    '';
  };

  # python3 для скриптов оболочки + модули для импорта паролей из браузеров
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.secretstorage ps.cryptography ]);
in
{
  home.packages = with pkgs; [
    quickshellPanacea # даёт команды qs и quickshell

    # терминал, обои, ночной режим
    foot
    hyprpaper
    hyprsunset
    mpvpaper # живые видео-обои

    # буфер обмена, скриншоты, запись экрана
    wl-clipboard
    cliphist
    grim
    slurp
    wf-recorder
    ffmpeg

    # голос → текст: Vulkan-сборка, считает на видеокарте; wtype печатает результат
    voxtype-vulkan
    wtype

    # яркость, звук, медиа, спектр
    brightnessctl
    ddcutil
    playerctl
    wireplumber # бинарник wpctl
    cava

    # то, на что опирается config.fish и скрипты
    eza
    zoxide
    bat
    fastfetch
    yazi
    pythonEnv
    jq
    openssl
    xdg-utils
    glib # gio: корзина и запуск .desktop
    curl
    file
    pciutils
    rsync # нужен panacea-sync.sh
    desktop-file-utils

    # диски в проводнике
    udiskie
  ];

  # ~/.local/bin (сюда sync кладёт скрипты из Panacea/bin) — в PATH после нового входа
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Курсор: Bibata Modern Classic, 24 px — для Hyprland, GTK и Xwayland сразу
  home.pointerCursor = {
    enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = "Bibata-Modern-Classic";
    cursor-size = 24;
  };

  # Демон голоса. Правый Alt слушает Hyprland (в конфиге Panacea) и дёргает `voxtype record start/stop`.
  systemd.user.services.voxtype = {
    Unit.Description = "Voxtype voice-to-text daemon";
    Service = {
      ExecStart = "${lib.getExe pkgs.voxtype-vulkan} -q daemon";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = [
        # RTX 4060 (в install.sh здесь стоял amd — это железо автора)
        "VOXTYPE_VULKAN_DEVICE=nvidia"
        # Hyprland обычно занимает wayland-1; нужен wtype, чтобы печатать в активное окно
        "WAYLAND_DISPLAY=wayland-1"
        "PATH=${lib.makeBinPath [ pkgs.wtype pkgs.wl-clipboard pkgs.coreutils ]}"
      ];
    };
    Install.WantedBy = [ "default.target" ];
  };
}
