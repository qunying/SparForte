------------------------------------------------------------------------------
-- Records Package Parser                                                   --
--                                                                          --
-- Part of SparForte                                                        --
------------------------------------------------------------------------------
--                                                                          --
--            Copyright (C) 2001-2016 Free Software Foundation              --
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

with bush_os,
     string_util,
     world,
     scanner,
     parser,
     parser_aux,
     parser_params;
use  bush_os,
     string_util,
     world,
     scanner,
     parser,
     parser_aux,
     parser_params;

package body parser_records is

------------------------------------------------------------------------------
-- Records package identifiers
------------------------------------------------------------------------------

records_to_json_t        : identifier;
records_to_record_t      : identifier;

---------------------------------------------------------
-- PARSE THE RECORDS PACKAGE
---------------------------------------------------------

procedure ParseRecordsToJson is
  -- Syntax: records.to_json( str, rec );
  -- Source: N/A
  target_ref    : reference;
  source_var_id : identifier;
  jsonString    : unbounded_string;
begin
  expect( records_to_json_t );
  expect( symbol_t, "(" );
  ParseOutParameter( target_ref, json_string_t );
  expect( symbol_t, "," );
  ParseIdentifier( source_var_id );
  if identifiers( getBaseType( identifiers( source_var_id ).kind ) ).kind /= root_record_t then
     err( "Record type expected" );
  end if;
  expect( symbol_t, ")" );
  if isExecutingCommand then
     DoRecordToJson( jsonString, source_var_id );
     assignParameter( target_ref, jsonString );
  end if;
end ParseRecordsToJson;

procedure ParseRecordsToRecord is
  -- Syntax: str := records.to_record( rec, str );
  -- Source: N/A
  target_var_id : identifier;
  sourceVal     : unbounded_string;
  sourceType    : identifier;
begin
  expect( records_to_record_t );
  expect( symbol_t, "(" );
  ParseIdentifier( target_var_id );  --ParseInOutParameter( target_ref );
  if identifiers( getBaseType( identifiers( target_var_id ).kind ) ).kind /= root_record_t then
     err( "Record type expected" );
  end if;
  expect( symbol_t, "," );
  ParseExpression( sourceVal, sourceType );
  if baseTypesOK( sourceType, json_string_t ) then
     expect( symbol_t, ")" );
  end if;
  if isExecutingCommand then
     DoJsonToRecord( target_var_id, sourceVal );
  end if;
end ParseRecordsToRecord;

-------------------------------------------------------------------------------
-- Housekeeping
-------------------------------------------------------------------------------

procedure StartupRecords is
begin
  declareNamespace( "records" );
  declareProcedure( records_to_json_t, "records.to_json", ParseRecordsToJSON'access );
  declareProcedure( records_to_record_t, "records.to_record", ParseRecordsToRecord'access );
  declareNamespaceClosed( "records" );
end StartupRecords;

procedure ShutdownRecords is
begin
  null;
end ShutdownRecords;

end parser_records;
