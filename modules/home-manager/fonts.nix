# Шрифты, иконки, курсор.
{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    papirus-icon-theme
    bibata-cursors
  ];
}
