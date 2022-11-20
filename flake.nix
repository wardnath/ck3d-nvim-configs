{
  description = "CK3Ds NVim configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
    nix2nvimrc.url = "github:ck3d/nix2nvimrc";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, nix2nvimrc }:
    utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import ./overlay.nix) ];
        nixpkgs' = import nixpkgs { inherit system overlays; };
        adminLanguages = [
          "nix"
          "yaml"
          "bash"
          # activate after merge of
          "markdown"
          "json"
          "toml"
        ];
        nvim = with nixpkgs'; name: languages:
          let
            rc = nixpkgs'.writeText
              ("nvimrc-" + name)
              (nix2nvimrc.lib.toRc nixpkgs' {
                inherit languages;
                imports = [ ./config.nix ];
              });
          in
          runCommandLocal
            "nvim"
            { nativeBuildInputs = [ makeWrapper ]; }
            ''
              ${neovim-unwrapped}/bin/nvim -u ${rc} --headless +"q"
              makeWrapper ${neovim-unwrapped}/bin/nvim $out/bin/nvim \
                --add-flags "-u ${rc}"
            ''
        ;
        packages = builtins.mapAttrs nvim {
          admin = adminLanguages;
          dev = adminLanguages ++ [
            # treesitter
            "lua"
            "rust"
            "beancount"
            "javascript"
            "html"
            "c"
            "cpp"
            "css"
            "make"
            "graphql"
            "python"
            "scheme"
            "latex"
            "devicetree"
            "go"
            # no treesitter
            "xml"
            "jq"
            "plantuml"
            "dhall"
          ];
        };
      in
      {
        inherit packages;
        defaultPackage = packages.admin;
      });
}
