# Home-manager для пользователя gefest на машине "nixos".
# username/homeDirectory задаются автоматически модулем NixOS.
{ ... }:

{
  imports = [
    ../../modules/home-manager/panacea.nix
    ../../modules/home-manager/cli.nix
    ../../modules/home-manager/fonts.nix
    ../../modules/home-manager/apps.nix
  ];

  home.stateVersion = "26.05";
}
