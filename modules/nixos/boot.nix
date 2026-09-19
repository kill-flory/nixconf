# Загрузчик GRUB (EFI) с темой Panacea и поиском других систем (os-prober).
{ inputs, pkgs, ... }:

let
  # Тема берётся из исходников Panacea; служебный скрипт сборки картинок не нужен на ESP
  grubTheme = pkgs.runCommand "grub-theme-panacea" { } ''
    cp -r --no-preserve=mode ${inputs.panacea}/grub/panacea $out
    rm -f $out/make_assets.py
  '';
in
{
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev"; # EFI: ставим на ESP, а не в MBR диска

    # Ищет Windows и другие системы и добавляет их в меню при КАЖДОЙ пересборке
    useOSProber = true;

    theme = grubTheme;
    splashImage = null; # свой фон у темы
    gfxmodeEfi = "1920x1080,auto";
    gfxpayloadEfi = "keep";

    # GRUB копирует ядра на ESP, поэтому держим не больше 10 поколений в меню
    configurationLimit = 10;
  };

  boot.loader.timeout = 5;

  # Если рядом стоит Windows и после неё в Linux сбивается время — раскомментируй:
  # time.hardwareClockInLocalTime = true;
}
