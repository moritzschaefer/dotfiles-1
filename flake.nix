{
  description = "Moritz's NixOS/home-manager configuration";

  # edition = 201909;

  inputs = {
    nixpkgs = {
      type = "github";
      # owner = "rasendubi";
      # repo = "nixpkgs";
      # ref = "melpa-2020-04-27";
      owner = "moritzschaefer";
      # repo = "nixpkgs-channels";
      repo = "nixpkgs";
      rev = "e52053d8473d5d350bc66ca3016684fe79587a87";
      # ref = "nixpkgs-unstable";
      ref = "master";
    };
    nixos-hardware = {
      type = "github";
      owner = "NixOS";
      repo = "nixos-hardware";
      flake = false;
    };
    nur = {
      url = github:nix-community/NUR;
    };
    home-manager = {
      type = "github";
      owner = "rycee";
      repo = "home-manager";
      ref = "bqv-flakes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, nur }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = self.overlays;
        config = { allowUnfree = true; };
      };
    in {
      nixosConfigurations =
        let
          hosts = ["moxps"];
          mkHost = name:
            nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [
                { nixpkgs = { inherit pkgs;  }; }
                (import ./nixos-config.nix)
                { nixpkgs.overlays = [ nur.overlay ]; }
              ];
              specialArgs = { inherit name inputs; };
            };
        in nixpkgs.lib.genAttrs hosts mkHost;

      packages.x86_64-linux =
        let
          mergePackages = nixpkgs.lib.foldr nixpkgs.lib.mergeAttrs {};
        in
          mergePackages [
            {
              # note it's a new attribute and does not override old one
              input-mono = (pkgs.input-fonts.overrideAttrs (old: {
                src = pkgs.requireFile {
                  name = "Input-Font.zip";
                  url = "https://input.fontbureau.com/build/?fontSelection=fourStyleFamily&regular=InputMonoNarrow-Regular&italic=InputMonoNarrow-Italic&bold=InputMonoNarrow-Bold&boldItalic=InputMonoNarrow-BoldItalic&a=0&g=0&i=topserif&l=serifs_round&zero=0&asterisk=height&braces=straight&preset=default&line-height=1.2&accept=I+do&email=";
                  sha256 = "888bbeafe4aa6e708f5c37b42fdbab526bc1d125de5192475e7a4bb3040fc45a";
                };
                outputHash = "1w2i660dg04nyc6fc6r6sd3pw53h8dh8yx4iy6ccpii9gwjl9val";
              }));
            }
          ];

      overlays = [
        (_self: _super: self.packages.x86_64-linux)
        
      ];

      homeManagerConfigurations.x86_64-linux =
        let
          hosts = ["MoritzSchaefer"];
          mkHost = hostname:
            home-manager.lib.homeManagerConfiguration {
              configuration = { ... }: {
                nixpkgs.config.allowUnfree = true;
                nixpkgs.overlays = self.overlays;
                imports = [(import ./.config/nixpkgs/home.nix)];
              };
              username = "moritz";
              homeDirectory = "/home/moritz";
              inherit system pkgs;
            };
        in nixpkgs.lib.genAttrs hosts mkHost;
    };
}
