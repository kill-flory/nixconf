# Экран входа SDDM с темой Panacea (вместо GDM).
{ inputs, pkgs, user, ... }:

let
  # Тема должна лежать в share/sddm/themes/<имя> внутри пакета
  sddmTheme = pkgs.runCommand "sddm-theme-panacea" { } ''
  d=$out/share/sddm/themes/panacea
  mkdir -p $out/share/sddm/themes
  cp -r --no-preserve=mode ${inputs.panacea}/sddm/panacea $d

  # SDDM 0.21 запускает Qt6-greeter только при QtVersion=6 в metadata.desktop
  m=$d/metadata.desktop
  sed -i '/^QtVersion=/d' $m
  sed -i '/^\[SddmGreeterTheme\]/a QtVersion=6' $m
'';
in
{
  services.displayManager.sddm = {
    enable = true;
    package = pkgs.kdePackages.sddm; # Qt 6, как ждёт тема
    theme = "panacea";
    # Экран входа на X11: с проприетарным NVIDIA это надёжнее. Сами сессии всё равно Wayland.
    # Попробовать Wayland-greeter: wayland.enable = true; (и убрать services.xserver.enable ниже)
  };
  services.xserver.enable = true;

  environment.systemPackages = [ sddmTheme ];

  # Тема рисует всё шрифтом JetBrainsMono Nerd Font, а greeter работает от пользователя sddm.
  # Шрифты из home-manager ему не видны — нужен системный.
  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  # Мостик к экрану входа: switch_theme.sh кладёт сюда размытые обои, акцент и язык,
  # а greeter (пользователь sddm) только читает. Права как у install.sh.
  systemd.tmpfiles.rules = [ "d /var/lib/panacea 0755 ${user} users -" ];

  # Ключница GNOME разблокируется при входе через SDDM (у GDM это работало само)
  security.pam.services.sddm.enableGnomeKeyring = true;
}
