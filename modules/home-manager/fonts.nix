# Шрифты и иконки (курсор — в panacea.nix).
{ config, pkgs, lib,  ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    papirus-icon-theme
    liberation_ttf
    corefonts
  ];

  # Разрешаем несвободный пакет corefonts
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "corefonts" ];

  # Автоматически копируем шрифты в ~/.local/share/fonts для OnlyOffice
  home.activation.copyFontsForOnlyOffice = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/share/fonts"
    cp -rL ${pkgs.corefonts}/share/fonts/truetype/* "$HOME/.local/share/fonts/"
    chmod 644 "$HOME"/.local/share/fonts/*
  '';

}
