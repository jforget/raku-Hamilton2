create table Maps (map       TEXT
                 , name      TEXT
                 , nb_macro  INTEGER
                 , nb_full   INTEGER
                 );

create table Areas (map      TEXT
                  , level    INTEGER
                  , code     TEXT
                  , name     TEXT
                  , long     NUMERIC
                  , lat      NUMERIC
                  , color    TEXT
                  , upper    TEXT
                  , nb_paths INTEGER
                  , exterior INTEGER
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
                   );

create table Paths   (map       TEXT
                   , level      INTEGER
                   , area       TEXT
                   , num        INTEGER
                   , path       TEXT
                   , from_code  TEXT
                   , to_code    TEXT
                   , cyclic     INTEGER
                   , macro_num  INTEGER
                   );

create table Path_Relations (map        TEXT
                           , full_num   INTEGER
                           , area       TEXT
                           , region_num INTEGER
                           );

create table Messages (map        TEXT
                    ,  dh         TEXT
                    ,  errcode    TEXT
                    ,  area       TEXT
                    ,  nb         INTEGER
                    ,  data       TEXT
                    );



create view Big_Areas (map, code, name, long, lat, color, nb_paths)
         as select     map, code, name, long, lat, color, nb_paths
            from       Areas
            where      level = 1;

create view Small_Areas (map, code, name, long, lat, color, upper, exterior)
         as select       map, code, name, long, lat, color, upper, exterior
            from         Areas
            where        level = 2;

create view Big_Borders (map, from_code, to_code, long, lat)
         as select       map, from_code, to_code, long, lat
            from         Borders
            where        level = 1;

create view Small_Borders (map, from_code, to_code, upper_from, upper_to, long, lat, color)
         as select         map, from_code, to_code, upper_from, upper_to, long, lat, color
            from           Borders
            where          level = 2;

create view Borders_With_Star (map, level, from_code, to_code, upper_from, upper_to)
               as select       map, level, from_code, to_code, upper_from, upper_to
                  from   Borders
                  where level = 2
            union select       map, 2    , '*'      , code   , '*'       , upper
                  from   Areas
                  where level = 2;

create view Macro_Paths   (map, num, path, from_code, to_code)
         as select         map, num, path, from_code, to_code
            from           Paths
            where          level = 1;

create view Region_Paths  (map, area, num, path, from_code, to_code)
         as select         map, area, num, path, from_code, to_code
            from           Paths
            where          level = 2;

create view Full_Paths    (map, num, path, from_code, to_code, macro_num)
         as select         map, num, path, from_code, to_code, macro_num
            from           Paths
            where          level = 3;
