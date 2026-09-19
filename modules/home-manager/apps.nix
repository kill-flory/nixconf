# Пользовательские программы.
{ pkgs, inputs, ... }:

{
  programs.firefox.enable = true;

  home.packages = with pkgs; [
    tree
    micro
    vscodium
    discord
    yandex-music
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
