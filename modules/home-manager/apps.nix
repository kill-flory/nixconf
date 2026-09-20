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

    tree
    micro
    vscodium
    discord
    vesktop
    yandex-music
    
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
        (writeShellScriptBin "zen-browser" ''exec zen-beta "$@"'')  
  ];


}
