# Hyprland (из апстрим-флейка). Службы для оболочки — в panacea.nix.
{ inputs, pkgs, ... }:

let
  hyprPkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Бинарный кэш Hyprland — без него он собирается из исходников
  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  programs.hyprland = {
    enable = true;
    package = hyprPkgs.hyprland;
    # портал должен быть той же версии, что и сам Hyprland
    portalPackage = hyprPkgs.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };
}
