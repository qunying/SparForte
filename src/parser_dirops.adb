------------------------------------------------------------------------------
-- Directory_Operations Package Parser                                      --
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

with text_io;use text_io;
with gnat.directory_operations,
    world,
    scanner,
    string_util,
    parser_aux,
    parser,
    bush_os;
use gnat.directory_operations,
    world, 
    scanner,
    string_util,
    parser_aux,
    parser,
    bush_os;

package body parser_dirops is

procedure ParseSingleDirNameStrExpression( expr_val : out unbounded_string;
  expr_type : out identifier ) is
begin
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, dirops_dir_name_str_t ) then
     expect( symbol_t, ")" );
  end if;
end ParseSingleDirNameStrExpression;

procedure ParseSinglePathNameExpression( expr_val : out unbounded_string;
  expr_type : out identifier ) is
begin
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, dirops_path_name_t ) then
     expect( symbol_t, ")" );
  end if;
end ParseSinglePathNameExpression;

procedure ParseDirOpsDirSeparator( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
begin
  expect( dirops_dir_separator_t );
  begin
    if isExecutingCommand then
       result := null_unbounded_string & dir_separator;
    end if;
  exception when directory_error =>
    err( "directory not accessible" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsDirSeparator;

procedure ParseDirOpsChangeDir is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
begin
  expect( dirops_change_dir_t );
  ParseSingleDirNameStrExpression( expr_val, expr_type );
  begin
    if isExecutingCommand then
       Change_Dir( dir_name_str( to_string( expr_val ) ) );
    end if;
  exception when directory_error =>
    err( "directory not accessible" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsChangeDir;

procedure ParseDirOpsMakeDir is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
begin
  expect( dirops_make_dir_t );
  ParseSingleDirNameStrExpression( expr_val, expr_type );
  begin
    if isExecutingCommand then
       Make_Dir( dir_name_str( to_string( expr_val ) ) );
    end if;
  exception when directory_error =>
    err( "directory not accessible" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsMakeDir;

procedure ParseDirOpsRemoveDir is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
  expr_val2 : unbounded_string;
  expr_type2: identifier;
begin
  expect( dirops_remove_dir_t );
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, dirops_dir_name_str_t ) then
     if token = symbol_t and identifiers( token ).value = "," then
        expect( symbol_t, "," );
        ParseExpression( expr_val2, expr_type2 );
        if baseTypesOk( expr_type2, boolean_t ) then
           null;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  declare
    recursive : boolean := expr_val2 = to_unbounded_string( "1" );
  begin
    if isExecutingCommand then
       Remove_Dir( dir_name_str( to_string( expr_val ) ), recursive);
    end if;
  exception when directory_error =>
    err( "directory cannot be removed" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsRemoveDir;

procedure ParseDirOpsGetCurrentDir( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
begin
  expect( dirops_get_current_dir_t );
  begin
    if isExecutingCommand then
       result := to_unbounded_string( get_current_dir );
    end if;
  exception when directory_error =>
    err( "directory not accessible" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsGetCurrentDir;

procedure ParseDirOpsDirName( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
begin
  expect( dirops_dir_name_t );
  ParseSinglePathNameExpression( expr_val, expr_type );
  begin
    if isExecutingCommand then
       result := to_unbounded_string( dir_name( path_name( to_string( expr_val ) ) ) );
    end if;
  exception when others =>
    err( "exception raised" );
  end;
end ParseDirOpsDirName;

procedure ParseDirOpsBaseName( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
  expr_val2 : unbounded_string;
  expr_type2: identifier;
begin
  expect( dirops_base_name_t );
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, dirops_path_name_t ) then
     if token = symbol_t and identifiers( token ).value = "," then
        expect( symbol_t, "," );
        ParseExpression( expr_val2, expr_type2 );
        if baseTypesOk( expr_type2, string_t ) then
           null;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  begin
    if isExecutingCommand then
       result := to_unbounded_string( base_name( path_name( to_string( expr_val ) ), to_string( expr_val2 ) ) );
    end if;
  exception when others =>
    err( "exception raised" );
  end;
end ParseDirOpsBaseName;

procedure ParseDirOpsFileExtension( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
begin
  expect( dirops_file_extension_t );
  ParseSinglePathNameExpression( expr_val, expr_type );
  begin
    if isExecutingCommand then
       result := to_unbounded_string( file_extension( path_name( to_string( expr_val ) ) ) );
    end if;
  exception when others =>
    err( "exception raised" );
  end;
end ParseDirOpsFileExtension;

procedure ParseDirOpsFileName( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
begin
  expect( dirops_file_name_t );
  ParseSinglePathNameExpression( expr_val, expr_type );
  begin
    if isExecutingCommand then
       result := to_unbounded_string( file_name( path_name( to_string( expr_val ) ) ) );
    end if;
  exception when others =>
    err( "exception raised" );
  end;
end ParseDirOpsFileName;

procedure ParseDirOpsFormatPathname( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
  expr_val2 : unbounded_string;
  expr_type2: identifier;
begin
  expect( dirops_format_pathname_t );
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, dirops_path_name_t ) then
     if token = symbol_t and identifiers( token ).value = "," then
        expect( symbol_t, "," );
        ParseExpression( expr_val2, expr_type2 );
        if baseTypesOk( expr_type2, dirops_path_style_t ) then
           null;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  declare
    style : path_style := system_default;
  begin
    if isExecutingCommand then
       -- not very elegant
       if expr_val2 = to_unbounded_string( "0" ) then
          style := UNIX;
       elsif expr_val2 = to_unbounded_string( "1" ) then
          style := DOS;
       elsif expr_val2 = to_unbounded_string( "2" ) then
          style := System_Default;
       end if;
       result := to_unbounded_string( format_pathname( path_name( to_string( expr_val ) ), style ) );
    end if;
  exception when directory_error =>
    err( "directory not accessible" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsFormatPathname;

procedure ParseDirOpsExpandPath( result : out unbounded_string ) is
  -- Syntax:
  -- Source:
  expr_val : unbounded_string;
  expr_type: identifier;
  expr_val2 : unbounded_string;
  expr_type2: identifier;
begin
  expect( dirops_expand_path_t );
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, dirops_path_name_t ) then
     if token = symbol_t and identifiers( token ).value = "," then
        expect( symbol_t, "," );
        ParseExpression( expr_val2, expr_type2 );
        if baseTypesOk( expr_type2, dirops_env_style_t ) then
           null;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  declare
    style : environment_style := System_Default;
  begin
    if isExecutingCommand then
       -- not very elegant
       if expr_val2 = to_unbounded_string( "0" ) then
          style := UNIX;
       elsif expr_val2 = to_unbounded_string( "1" ) then
          style := DOS;
       elsif expr_val2 = to_unbounded_string( "2" ) then
          style := Both;
       elsif expr_val2 = to_unbounded_string( "3" ) then
          style := System_Default;
       end if;
       result := to_unbounded_string( expand_path( path_name( to_string( expr_val ) ), style ) );
    end if;
  exception when directory_error =>
    err( "directory not accessible" );
  when others =>
    err( "exception raised" );
  end;
end ParseDirOpsExpandPath;

procedure StartupDirOps is
begin
  declareIdent( dirops_dir_name_str_t, "directory_operations.dir_name_dir",
     string_t, subClass );
  declareProcedure( dirops_dir_separator_t, "directory_operations.dir_separator" );
  declareProcedure( dirops_change_dir_t, "directory_operations.change_dir" );
  declareProcedure( dirops_make_dir_t, "directory_operations.make_dir" );
  declareProcedure( dirops_remove_dir_t, "directory_operations.remove_dir" );
  declareFunction( dirops_get_current_dir_t, "directory_operations.get_current_dir" );
  declareIdent( dirops_path_name_t, "directory_operations.path_name",
     string_t, subClass );
  declareFunction( dirops_dir_name_t, "directory_operations.dir_name" );
  declareFunction( dirops_base_name_t, "directory_operations.base_name" );
  declareFunction( dirops_file_extension_t, "directory_operations.file_extension" );
  declareFunction( dirops_file_name_t, "directory_operations.file_name" );
  declareIdent( dirops_path_style_t, "directory_operations.path_style",
     root_enumerated_t, typeClass );
  declareStandardConstant( dirops_path_style_unix_t, "path_style.unix",
     dirops_path_style_t, "0" );
  declareStandardConstant( dirops_path_style_dos_t, "path_style.dos",
     dirops_path_style_t, "1" );
  declareStandardConstant( dirops_path_style_system_default_t, "path_style.system_default",
     dirops_path_style_t, "2" );
  declareFunction( dirops_format_pathname_t, "directory_operations.format_pathname" );
  declareIdent( dirops_env_style_t, "directory_operations.environment_style",
     root_enumerated_t, typeClass );
  declareStandardConstant( dirops_env_style_unix_t, "environment_style.unix",
     dirops_env_style_t, "0" );
  declareStandardConstant( dirops_env_style_dos_t, "environment_style.dos",
     dirops_env_style_t, "1" );
  declareStandardConstant( dirops_env_style_both_t, "environment_style.both",
     dirops_env_style_t, "2" );
  declareStandardConstant( dirops_env_style_system_default_t, "environment_style.system_default",
     dirops_env_style_t, "3" );
  declareFunction( dirops_expand_path_t, "directory_operations.expand_path" );
end StartupDirOps;

procedure ShutdownDirOps is
begin
  null;
end ShutdownDirOps;

end parser_dirops;
