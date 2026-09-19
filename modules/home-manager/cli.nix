# Терминальные утилиты и шелл.
{ pkgs, ... }:

{
  programs.fish.enable = true;
  programs.bash.enable = true;

  home.shellAliases = {
    # --sudo: конфиг вычисляется от твоего пользователя, root нужен только для активации
    rebuild = "nixos-rebuild switch --flake ~/.config/nixconf#nixos --sudo";
  };

  home.packages = with pkgs; [
    btop
    eza
    zoxide
    bat
    fastfetch
    yazi
    pciutils
  ];
}
