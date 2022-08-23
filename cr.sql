create table Maps (map TEXT, name TEXT);

create table Areas (map      TEXT
                  , level    INTEGER
                  , code     TEXT
                  , name     TEXT
                  , long     NUMERIC
                  , lat      NUMERIC
                  , color    TEXT
                  , upper    TEXT
                  );

create table Borders (map       TEXT
                   , level      INTEGER
                   , from_code  TEXT
                   , to_code    TEXT
                   , upper_from TEXT
                   , upper_to   TEXT
                   , long       NUMERIC
                   , lat        NUMERIC
                   );

create view Big_Areas (map, code, name, long, lat, color)
         as select     map, code, name, long, lat, color
            from       Areas
            where      level = 1;

create view Small_Areas (map, code, name, long, lat, color, upper)
         as select       map, code, name, long, lat, color, upper
            from         Areas
            where        level = 2;

create view Big_Borders (map, from_code, to_code, long, lat)
         as select       map, from_code, to_code, long, lat
            from         Borders
            where        level = 1;

create view Small_Borders (map, from_code, to_code, upper_from, upper_to, long, lat)
         as select         map, from_code, to_code, upper_from, upper_to, long, lat
            from           Borders
            where          level = 2;
