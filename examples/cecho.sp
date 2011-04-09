#!/usr/local/bin/bush

-- cecho
-- An "echo" beautifier - supports colours and boldface
-- based on http://www.zazzybob.com/bin/cecho.html
-- Created by Ken O. Burtch

pragma annotate( "cecho" );
pragma annotate( "" );
pragma annotate( "echo with color or boldface" );
pragma annotate( "usage: cecho style text" );

pragma restriction( no_external_commands );

procedure cecho is

  procedure usage is
  begin
     put( "usage: " ) @ ( source_info.file );
     put_line( " style text" );
     command_line.set_exit_status( 0 );
  end usage;

  open_escape : string := ASCII.ESC & "[0m";
  close_escape : string := ASCII.ESC & "[0m";

begin

  -- Usage

  if $# /= 1 then
     usage;
     return;
  elsif $1 = "-h" or $1 = "--help" then
     usage;
     return;
  end if;

  -- Interpret the colour parameter

  if $1 = "red" then
     open_escape := ASCII.ESC & "[31m";
  elsif $1 = "green" then
     open_escape := ASCII.ESC & "[32m";
  elsif $1 = "blue" then
     open_escape := ASCII.ESC & "[33m";
  elsif $1 = "purple" then
     open_escape := ASCII.ESC & "[34m";
  elsif $1 = "cyan" then
     open_escape := ASCII.ESC & "[35m";
  elsif $1 = "grey" then
     open_escape := ASCII.ESC & "[36m";
  elsif $1 = "white" then
     open_escape := ASCII.ESC & "[1;37m";
  elsif $1 = "bold" then
     open_escape := ASCII.ESC & "[1m";
  else
     null;
  end if;

  -- Display the message with colour

  put_line( open_escape & $1 & close_escape );

  command_line.set_exit_status( 0 );

end cecho;

-- VIM editor formatting instructions -- vim: ft=bush
