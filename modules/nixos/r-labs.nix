{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    (rWrapper.override {
      packages = with rPackages; [
        # Лаб 1: распараллеливание + Rcpp
        foreach
        doSNOW
        snow
        Rcpp

        # Лаб 2: метод главных координат
        stringdist

        # Лаб 3: иерархическая кластеризация
        dendextend

        # Удобные мелочи для отчётов/графиков
        ggplot2
      ];
    })
  ];
}
