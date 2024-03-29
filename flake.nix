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
          l = p.lib;

          inherit (inputs.shelpers.lib p) eval-shelpers shelp;

          shelpers =
            eval-shelpers [
              ({ config, ... }: {
                instructions-order = [ "General" ];
                cache = false;
                shelpers."." = {
                  General = {
                    shelp = shelp config;
                  };

                  Database =
                    let pg-dir = ".database"; in {
                      create-db = {
                        description = "create the local database";
                        # internal = true;
                        script = ''
                          if [[ -e ${pg-dir} ]]; then
                            echo database has already been created
                          else
                            lpg make ${pg-dir}
                            db-server-start
                            yarn prisma db push
                            db-server-stop
                          fi
                        '';
                      };

                      db-server-start = {
                        description = "start the database server";
                        script = ''
                          lpg on ${pg-dir} up
                          echo "DATABASE_URL=\"$(lpg on ${pg-dir} get-connstr)\"" > .env
                        '';
                      };

                      db-server-stop = {
                        description = "stop the database server";
                        script = ''
                          lpg on ${pg-dir} down
                          rm .env
                        '';
                      };

                      db-shell = {
                        description = "enter a psql shell for the local database";
                        script = ''
                          db-server-start
                          lpg on ${pg-dir} psql
                        '';
                      };

                      reset-db = {
                        description = "destroy (if it exists) and then recreate the local database";
                        script = ''
                          trap - ERR
                          destroy-db
                          create-db
                        '';
                      };

                      destroy-db = {
                        description = "destroy the local database";
                        script = ''
                          db-server-stop
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
          packages.default = p.prisma-engines;
          devShells.default = p.mkShell {
            packages = with p; [
              nodejs
              openssl
              prisma-engines
              yarn
              (import inputs.local-postgres { inherit pkgs; })
            ];

            shellHook = ''
              ${shelpers.functions}
              shelp
            '';

            PRISMA_QUERY_ENGINE_LIBRARY = "${p.prisma-engines}/lib/libquery_engine.node";
            PRISMA_QUERY_ENGINE_BINARY = "${p.prisma-engines}/bin/query-engine";
            PRISMA_SCHEMA_ENGINE_BINARY = "${p.prisma-engines}/bin/schema-engine";
          };

          checks =
            let
              lu = lint-utils.linters.${system};
              nixOnly = onlyExts [ "nix" ] ./.;
            in
            {
              nix-formatting = lu.nixpkgs-fmt { src = nixOnly; };
              nix-dce = lu.deadnix { src = nixOnly; };
              nix-linting = lu.statix { src = nixOnly; };
            };

          inherit (shelpers) apps;

          formatter = lu-pkgs.nixpkgs-fmt;
          shelpers = shelpers.files;
        });
}
