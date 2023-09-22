create table Maps (map               TEXT
                 , name              TEXT
                 , nb_macro          INTEGER
                 , nb_full           INTEGER
                 , nb_generic        INTEGER
                 , fruitless_reason  TEXT
                 );

create table Areas (map      TEXT
                  , level    INTEGER
                  , code     TEXT
                  , name     TEXT
                  , long     NUMERIC
                  , lat      NUMERIC
                  , color    TEXT
                  , upper    TEXT
                  , nb_macro_paths  INTEGER
                  , nb_region_paths INTEGER
                  , exterior        INTEGER
                  );

create table Borders (map       TEXT
                   , level      INTEGER
                   , from_code  TEXT
                   , to_code    TEXT
                   , upper_from TEXT
                   , upper_to   TEXT
                   , long       NUMERIC
                   , lat        NUMERIC
                   , color      TEXT
                   , fruitless  INTEGER
                   , nb_paths   INTEGER
                   );

create table Paths   (map       TEXT
                   , level      INTEGER
                   , area       TEXT
                   , num        INTEGER
                   , path       TEXT
                   , from_code         TEXT
                   , to_code           TEXT
                   , cyclic            INTEGER
                   , macro_num         INTEGER
                   , fruitless         INTEGER
                   , fruitless_reason  TEXT
                   , generic_num       INTEGER
                   , first_num         INTEGER
                   , paths_nb          INTEGER
                   , num_s2g           INTEGER
                   );

create table Path_Relations (map        TEXT
                           , full_num   INTEGER
                           , area       TEXT
                           , region_num INTEGER
                           , range1     INTEGER
                           , coef1      INTEGER
                           , coef2      INTEGER
                           );

create table Messages (map        TEXT
                    ,  dh         TEXT
                    ,  errcode    TEXT
                    ,  area       TEXT
                    ,  nb         INTEGER
                    ,  data       TEXT
                    );

create table Exit_Borders (map       TEXT
                         , from_code  TEXT
                         , upper_from TEXT
                         , upper_to   TEXT
                         , spoc       INTEGER
                         );

create table Isometries   (isometry   TEXT
                         , transform  TEXT
                         , length     INTEGER
                         , recipr     TEXT
                         , involution INTEGER
                         );

create table Isom_Path    (canonical_num INTEGER
                         , num        INTEGER
                         , isometry   TEXT
                         , recipr     TEXT
                         );



create view Big_Areas (map, code, name, long, lat, color, nb_region_paths, nb_macro_paths)
         as select     map, code, name, long, lat, color, nb_region_paths, nb_macro_paths
            from       Areas
            where      level = 1;

create view Small_Areas (map, code, name, long, lat, color, upper, nb_region_paths, exterior)
         as select       map, code, name, long, lat, color, upper, nb_region_paths, exterior
            from         Areas
            where        level = 2;

create view Big_Borders (map, from_code, to_code, long, lat, fruitless, nb_paths)
         as select       map, from_code, to_code, long, lat, fruitless, nb_paths
            from         Borders
            where        level = 1;

create view Small_Borders (map, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless, nb_paths)
         as select         map, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless, nb_paths
            from           Borders
            where          level = 2;

create view Borders_With_Star (map, level, from_code, to_code, upper_from, upper_to)
               as select       map, level, from_code, to_code, upper_from, upper_to
                  from   Borders
                  where level = 2
            union select       map, 2    , '*'      , code   , '*'       , upper
                  from   Areas
                  where level = 2;

create view Macro_Paths   (map, num, path, from_code, to_code, fruitless, fruitless_reason)
         as select         map, num, path, from_code, to_code, fruitless, fruitless_reason
            from           Paths
            where          level = 1;

create view Region_Paths  (map, area, num, path, from_code, to_code, generic_num, num_s2g)
         as select         map, area, num, path, from_code, to_code, generic_num, num_s2g
            from           Paths
            where          level = 2;

create view Generic_Region_Paths  (map, area, num, path, from_code, to_code, first_num, paths_nb)
         as select                 map, area, num, path, from_code, to_code, first_num, paths_nb
            from                   Paths
            where                  level = 4;

create view Full_Paths    (map, num, path, from_code, to_code, macro_num, first_num, paths_nb)
         as select         map, num, path, from_code, to_code, macro_num, first_num, paths_nb
            from           Paths
            where          level = 3;

