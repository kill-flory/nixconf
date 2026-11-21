# Пользовательские программы.
{ pkgs, inputs, ... }:

{
  programs.firefox.enable = true;
  

  home.packages = with pkgs; [
    telegram-desktop
    onlyoffice-desktopeditors
    #openrgb
    #openrgb-with-all-plugins
    qbittorrent
    amnezia-vpn
    rstudio

    droidcam
    android-tools # предоставляет adb

    rhythmbox
    libgpod
    pkgs.iloader

    tree
    micro
    vscodium
    discord
    yandex-music
    obsidian

    #ide
    #jetbrains.pycharm
    vesktop
    rstudio
    R

    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        (writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')  
  ];


}
