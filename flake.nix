{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    lint-utils = {
      url = "github:homotopic/lint-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    local-postgres = {
      url = "github:quelklef/local-postgres";
      flake = false;
    };
    shelpers.url = "gitlab:platonic/shelpers";
  };

  outputs =
    inputs@{ lint-utils, nixpkgs, ... }:
      with builtins;
      inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ]
        (system:
        let
          pkgs = import nixpkgs { inherit system; };
          p = pkgs;

          inherit (inputs.shelpers.lib p) eval-shelpers;

          shelpers =
            eval-shelpers [
              ({ shelp, config, ... }: {
                instructions-order = [ "General" "Yarn" ];
                root-file = ".git";
                shelpers."." = {
                  General = { inherit shelp; };

                  # adding these redundent scripts to make shelp more helpful
                  Yarn = {
                    "yarn.install" = {
                      description = "yarn install";
                      script = ''yarn install'';
                    };

                    "yarn.lint" = {
                      description = "yarn lint";
                      script = ''yarn lint "@1"'';
                    };

                    "yarn.serve" = {
                      description = "yarn serve";
                      script = "yarn serve";
                    };
                  };
                  Database =
                    let pg-dir = ".database"; in {
                      "db.create" = {
                        description = "create the local database";
                        internal = true;
                        script = ''
                          if [[ -e ${pg-dir} ]]; then
                            echo database has already been created
                          else
                            lpg make ${pg-dir}
                            db.start
                            yarn db:sync
                            db.stop
                          fi
                        '';
                      };

                      "db.start" = {
                        description = "start the database server";
                        script = ''
                          lpg on ${pg-dir} up
                          echo "DATABASE_URL=\"$(lpg on ${pg-dir} get-connstr)\"" > .env
                        '';
                      };

                      "db.stop" = {
                        description = "stop the database server";
                        script = ''
                          lpg on ${pg-dir} down
                          rm .env -f
                        '';
                      };

                      "db.shell" = {
                        description = "enter a psql shell for the local database";
                        script = ''
                          db.start
                          lpg on ${pg-dir} psql
                        '';
                      };

                      "db.reset" = {
                        description = "destroy (if it exists) and then recreate the local database";
                        exit-on-error = false;
                        script = ''
                          db.destroy
                          db.create
                        '';
                      };

                      "db.destroy" = {
                        description = "destroy the local database";
                        script = ''
                          db.stop
                          rm ${pg-dir} -r
                        '';
                      };
                    };
                };
              })
            ];

          lu-pkgs = lint-utils.packages.${system};
        in
        {
          devShells.default = p.mkShell {
            packages = with p; [
              cypress
              nodejs
              openssl
              yarn
              (import inputs.local-postgres { inherit pkgs; })
            ];

            shellHook = ''
              ${shelpers.functions}
              shelp
            '';
          };

          checks =
            let lu = lint-utils.linters.${system}; in {
              nix-formatting = lu.nixpkgs-fmt { src = ./.; };
              nix-dce = lu.deadnix { src = ./.; };
              nix-linting = lu.statix { src = ./.; };
            };

          inherit (shelpers) apps;

          formatter = lu-pkgs.nixpkgs-fmt;
          shelpers = shelpers.files;
        });
}
