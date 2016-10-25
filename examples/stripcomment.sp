#!/usr/local/bin/spar

pragma annotate( summary, "stripcomment" )
       @( description, "The task is to remove text that follow any of a set of" )
       @( description, "comment markers, (in these examples either a hash or a" )
       @( description, "semicolon) from a string or input line." )
       @( see_also, "http://rosettacode.org/wiki/Strip_comments_from_a_string" )
       @( author, "Ken O. Burtch" );
pragma license( unrestricted );

pragma restriction( no_external_commands );

procedure stripcomment is
  line : constant string := get_line;
  eol  : natural := 0;
  ch   : character;
begin
  for i in 1..strings.length( line ) loop
    ch := strings.element( line, i );
    exit when ch = '#' or ch = ';';
    eol := i;
  end loop;
  if eol > 0 then
     ? strings.slice( line, 1, eol );
  end if;
end stripcomment;

-- VIM editor formatting instructions
-- vim: ft=spar

