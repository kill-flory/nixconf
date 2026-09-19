# GNOME + GDM. GDM показывает и сессию GNOME, и сессию Hyprland.
{ ... }:

{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
}
