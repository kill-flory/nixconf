# PC HUD: веб-страничка с сенсорами и визуализацией RGB. http://localhost:8090
{ config, pkgs, ... }:
let
  py = pkgs.python3.withPackages (ps: [ ps.openrgb-python ]);
in
{
  # intel_rapl_msr — мощность CPU (RAPL работает и на Zen); spd5118 — температура DIMM DDR5
  boot.kernelModules = [ "intel_rapl_msr" "spd5118" ];

  systemd.services.pc-hud = {
    description = "PC HUD (sensors + OpenRGB visualiser)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "openrgb.service" ];
    path = [ config.hardware.nvidia.package.bin ]; # nvidia-smi
    environment = {
      HUD_DIR = "${../../hud}";
      HUD_HOST = "127.0.0.1"; # "0.0.0.0" чтобы открывать с других устройств
      HUD_PORT = "8090";
    };
    serviceConfig = {
      ExecStart = "${py}/bin/python ${../../hud/server.py}";
      DynamicUser = true;
      Restart = "on-failure";
      # energy_uj (RAPL) читается только root'ом — даём только право чтения файлов
      AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
      CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
    };
  };

  # Для доступа с телефона/другого ПК: HUD_HOST = "0.0.0.0" + раскомментировать
  # networking.firewall.allowedTCPPorts = [ 8090 ];
}
