#!/usr/local/bin/spar

pragma annotate( summary, "aplusb" )
       @( description, "A+B - in programming contests, classic problem, which is given so" )
       @( description, "contestants can gain familiarity with online judging system being used. " )
       @( description, "A+B is one of few problems on contests, which traditionally lacks fabula." )
       @( description, "Given 2 integer numbers, A and B. One needs to find their sum. " )
       @( description, "A Rosetta Code Example" )
       @( author, "Ken O. Burtch" );
pragma license( unrestricted );

pragma restriction( no_external_commands );

procedure aplusb is
  s : string;
  a : integer;
  b : integer;
begin
  -- get( a ) @ ( b ) doesn't work in AdaScript since there's no integer_io.get()
  s := get_line;
  a := numerics.value( strings.field( s, 1, ' ' ) );
  b := numerics.value( strings.field( s, 2, ' ' ) );
  ? a+b;
end aplusb;

-- VIM editor formatting instructions
-- vim: ft=spar
