{
  description = "NixOS config: Ryzen 5 7500F + RTX 4060, Hyprland (Panacea) + GNOME";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Свежий Hyprland из апстрима.
    # nixpkgs намеренно НЕ подменяем (follows), иначе не сработает бинарный кэш hyprland.cachix.org
    hyprland.url = "github:hyprwm/Hyprland";

    # Quickshell — тулкит, на котором построен Panacea
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    panacea = {
      url = "github:EnsixD/Panacea";
      flake = false;
    };

    # Zen Browser — пока не в nixpkgs
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      user = "gefest";

      # Собирает систему из hosts/<hostname>/{configuration,home}.nix
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs user hostname; };
        modules = [
          ./hosts/${hostname}/configuration.nix

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # если в ~/.config уже лежит файл, который теперь ведёт home-manager,
              # он будет переименован в *.backup, а не сломает сборку
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit inputs; };
              users.${user} = import ./hosts/${hostname}/home.nix;
            };
          }
        ];
      };
    in
    {
      nixosConfigurations.nixos = mkHost "nixos";
    };
}
