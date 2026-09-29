{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    lutris
    wineWowPackages.stable
    winetricks
  ];

  # Если этот блок уже есть в твоём audio.nix — не дублируй, а просто
  # добавь недостающие строки (rtkit, jack.enable, группа audio) в него.
  # security.rtkit.enable = true;

  #services.pipewire = {
  #  enable = true;
  #  alsa.enable = true;
  #  alsa.support32Bit = true;
  #  pulse.enable = true;
  # jack.enable = true; # нужен части DAW-обвязки под Wine
  # };

  users.users.gefest.extraGroups = [ "audio" ];
}
