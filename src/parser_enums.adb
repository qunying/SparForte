------------------------------------------------------------------------------
-- Enums Package Parser                                                     --
--                                                                          --
-- Part of SparForte                                                        --
------------------------------------------------------------------------------
--                                                                          --
--            Copyright (C) 2001-2011 Free Software Foundation              --
--                                                                          --
-- This is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  This is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with this;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- This is maintained at http://www.pegasoft.ca                             --
--                                                                          --
------------------------------------------------------------------------------

with gnat.bubble_sort_a,
     gnat.heap_sort_a,
     ada.numerics.float_random,
     bush_os,
     string_util,
     world,
     parser,
     parser_aux;
use  bush_os,
     string_util,
     world,
     parser,
     parser_aux;
with ada.text_io; use ada.text_io;

package body parser_enums is


---------------------------------------------------------
-- PARSE THE ENUMS PACKAGE
---------------------------------------------------------

procedure ParseEnumsFirst( f : out unbounded_string; kind : out identifier ) is
  -- Syntax: enums.first( arraytypeorvar );
  -- Source: enumtype'first
  var_id   : identifier;
begin
  expect( enums_first_t );
  expect( symbol_t, "(" );
  ParseIdentifier( var_id );
  kind := var_id ;
  if identifiers( var_id ).class = typeClass or
     identifiers( var_id ).class = subClass then
     if identifiers( var_id ).kind /= root_enumerated_t then
        var_id := getBaseType( var_id );
        if identifiers( var_id ).kind /= root_enumerated_t then
           err( "Enumerated type expected" );
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  if isExecutingCommand then
     -- first item in an enumerated type is always value 0
     f := to_unbounded_string( "0" );
  elsif syntax_check then
     kind := universal_t; -- type is unknown during syntax check
  end if;
end ParseEnumsFirst;

procedure ParseEnumsLast( f : out unbounded_string; kind : out identifier ) is
  -- Syntax: enums.last( arraytypeorvar );
  -- Source: enumtype'last
  var_id   : identifier;
  best     : integer;
  candidate: integer;
begin
  expect( enums_last_t );
  expect( symbol_t, "(" );
  ParseIdentifier( var_id );
  kind := var_id ;
  if identifiers( var_id ).class = typeClass or
     identifiers( var_id ).class = subClass then
     if identifiers( var_id ).kind /= root_enumerated_t then
        var_id := getBaseType( var_id );
        if identifiers( var_id ).kind /= root_enumerated_t then
           err( "Enumerated type expected" );
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  if isExecutingCommand then
     best := -1;
     for id in reverse keywords_top..identifiers_top loop
        if identifiers( id ).kind = var_id then
           if identifiers( id ).class = constClass then
              candidate := integer( to_numeric( identifiers( id ).value ) );
              if candidate > best then
                 best := candidate;
              end if;
           end if;
        end if;
     end loop;
     -- convert to string and remove leading space
     declare
        s : string := best'img;
     begin
        --f := to_unbounded_string( s(2..s'last) );
        f := to_unbounded_string( s );
     end;
  elsif syntax_check then
     kind := universal_t; -- type is unknown during syntax check
  end if;
end ParseEnumsLast;

procedure ParseEnumsPred( f : out unbounded_string; kind : out identifier ) is
--  -- Syntax: enums.prev( arraytypeorvar );
--  -- Source: enumvar'prev
  var_id   : identifier;
  item     : natural;
begin
  expect( enums_pred_t );
  expect( symbol_t, "(" );
  ParseIdentifier( var_id );
  kind := identifiers( var_id ).kind;
  if identifiers( var_id ).class /= constClass then
     err( "Enumerated item expected" );
  else
     kind := getBaseType( identifiers( var_id ).kind );
     if identifiers( kind ).kind /= root_enumerated_t then
        err( "Enumerated item expected" );
     end if;
  end if;
  expect( symbol_t, ")" );
  if isExecutingCommand then
     item := natural( to_numeric( identifiers( var_id ).value ) );
     begin
        item := item - 1;
        -- convert to string and remove leading space
        declare
           s : string := item'img;
        begin
           --f := to_unbounded_string( s(2..s'last) );
           f := to_unbounded_string( s );
        end;
     exception when others =>
        err( "exception thrown" );
     end;
  elsif syntax_check then
     kind := universal_t; -- type is unknown during syntax check
  end if;
end ParseEnumsPred;

procedure ParseEnumsSucc( f : out unbounded_string; kind : out identifier ) is
  -- Syntax: enums.succ( arraytypeorvar );
  -- Source: enumvar'succ
  var_id   : identifier;
  item     : natural;
begin
  expect( enums_succ_t );
  expect( symbol_t, "(" );
  ParseIdentifier( var_id );
  kind := identifiers( var_id ).kind;
  if identifiers( var_id ).class /= constClass then
     err( "Enumerated item expected" );
  else
     kind := getBaseType( identifiers( var_id ).kind );
     if identifiers( kind ).kind /= root_enumerated_t then
        err( "Enumerated item expected" );
     end if;
  end if;
  expect( symbol_t, ")" );
  if isExecutingCommand then
     item := natural( to_numeric( identifiers( var_id ).value ) );
     declare
        ok : boolean := false;
        candidate : natural;
     begin
        item := item + 1;
        for id in reverse keywords_top..identifiers_top loop
           if identifiers( id ).kind = kind then
              if identifiers( id ).class = constClass then
                 candidate := integer( to_numeric( identifiers( id ).value ) );
                 if candidate = item then
                    ok := true;
                    exit;
                 end if;
              end if;
           end if;
        end loop;
        -- if beyond end, raise exception
        if not ok then
           raise CONSTRAINT_ERROR;
        end if;
        -- convert to string and remove leading space
        declare
           s : string := item'img;
        begin
           --f := to_unbounded_string( s(2..s'last) );
           f := to_unbounded_string( s );
        end;
     exception when others =>
        err( "exception thrown" );
     end;
  elsif syntax_check then
     kind := universal_t; -- type is unknown during syntax check
  end if;
end ParseEnumsSucc;

-------------------------------------------------------------------------------
-- Housekeeping
-------------------------------------------------------------------------------

procedure StartupEnums is
begin
  declareFunction( enums_first_t, "enums.first" );
  declareFunction( enums_last_t, "enums.last" );
  declareFunction( enums_pred_t, "enums.pred" );
  declareFunction( enums_succ_t, "enums.succ" );
end StartupEnums;

procedure ShutdownEnums is
begin
  null;
end ShutdownEnums;

end parser_enums;