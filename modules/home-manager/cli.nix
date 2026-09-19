# Терминальные утилиты. fish и его конфиг ведёт Panacea, поэтому HM их не трогает.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    btop
    lavat
    


    # Команда `rebuild` во всех шеллах (bash, fish, ...).
    # --sudo: конфиг вычисляется от твоего пользователя, root нужен только для активации
    (writeShellScriptBin "rebuild" ''
      exec nixos-rebuild switch --flake "$HOME/.config/nixconf#nixos" --sudo "$@"
    '')
  ];
}
