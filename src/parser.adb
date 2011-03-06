------------------------------------------------------------------------------
-- AdaScript Language Parser                                                --
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

pragma warnings( off ); -- suppress Gnat-specific package warning
with ada.command_line.environment;
pragma warnings( on );
with system,
    ada.text_io.editing,
    ada.strings.unbounded.text_io,
    ada.characters.handling,
    ada.numerics.float_random,
    ada.calendar,
    gnat.regexp,
    gnat.directory_operations,
    cgi,
    bush_os.exec,
    bush_os.sound,
    string_util,
    user_io,
    script_io,
    builtins,
    jobs,
    signal_flags,
    parser_tio,
    parser_strings,
    parser_numerics,
    parser_arrays,
    parser_enums,
    parser_cal,
    parser_cgi,
    parser_cmd,
    parser_db,
    parser_mysql,
    parser_files,
    parser_lock,
    parser_units,
    parser_stats,
    parser_pen,
    parser_os,
    parser_dirops;
use ada.text_io,
    ada.text_io.editing,
    ada.command_line,
    ada.command_line.environment,
    ada.strings.unbounded,
    ada.strings.unbounded.text_io,
    ada.characters.handling,
    gnat.regexp,
    gnat.directory_operations,
    bush_os,
    bush_os.exec,
    bush_os.sound,
    user_io,
    script_io,
    string_util,
    builtins,
    jobs,
    signal_flags,
    parser_tio,
    parser_strings,
    parser_numerics,
    parser_arrays,
    parser_enums,
    parser_cal,
    parser_cgi,
    parser_cmd,
    parser_db,
    parser_mysql,
    parser_files,
    parser_lock,
    parser_units,
    parser_stats,
    parser_pen,
    parser_os,
    parser_dirops;

package body parser is


---------------------------------------------------------
-- START OF ADASCRIPT PARSER
---------------------------------------------------------

procedure RunAndCaptureOutput( s : unbounded_string; results : out
  unbounded_string; fragment : boolean := true );
-- forward declaration: this runs the commands found in string s

procedure CompileRunAndCaptureOutput( commands : unbounded_string; results : out
  unbounded_string );

procedure ParseBasicShellWord( shell_word : out unbounded_string ) is
  -- Check token for a shell word.
begin
  shell_word := null_unbounded_string;
  if identifiers( token ).kind = command_t then   -- handle a command type
      shell_word := identifiers( token ).value;
      getNextToken;
  elsif token = symbol_t then
     if identifiers( token ).value = ";" then
        err( "shell word expected" );
     end if;
     shell_word := identifiers( token ).value;
     getNextToken;
  elsif token = word_t then
     shell_word := identifiers( token ).value;
     getNextToken;
  elsif token = cd_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = clear_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = env_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = help_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = history_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = jobs_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = pwd_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = trace_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = unset_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = wait_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = alter_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = delete_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = insert_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = select_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = update_t then
     shell_word := identifiers( token ).name;
     getNextToken;
  elsif token = strlit_t then
     shell_word := identifiers( token ).value;
     discardUnusedIdentifier( token );
     getNextToken;
  elsif identifiers( token ).kind = new_t then
     shell_word := identifiers( token ).name;
     discardUnusedIdentifier( token );
     getNextToken;
  elsif token = number_t then
     err( optional_bold( "shell word") & " expected, not a " &
          optional_bold( "number" ) );
  elsif token = strlit_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "string literal" ) );
  elsif token = charlit_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "character literal" ) );
  elsif token = backlit_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "backquoted literal" ) );
  elsif token = word_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "(shell immediate) word" ) );
  elsif token = eof_t then
     err( optional_bold( "shell word" ) & " or semi-colon expected" );
  elsif is_keyword( token ) then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "keyword" ) );
  elsif token = symbol_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "symbol" ) );
  elsif identifiers( token ).field_of /= eof_t then
     err( optional_bold( "shell word" ) & " expected, not a " &
          optional_bold( "field of a record type" ) );
  else
     err( "shell word expected" );
  end if;
  --if identifiers( token ).kind /= new_t then
    --else
      -- err( "shell word expected" );
    --end if;
end ParseBasicShellWord;

procedure ParseFieldIdentifier( record_id : identifier; id : out identifier ) is
  -- Expect a new identifier, or one declared in this scope, but
  -- if one from another scope it will need to be redeclared in
  -- this scope.  Use this for record fields that might possibly
  -- be already declared in a different scope.
  --   The problem is that a field variable has a name of "r.f" not "f" as it
  -- appears in the source code.  When testing for existence, we need to
  -- use the full name of the field variable.
  fieldName : unbounded_string;
  temp_id   : identifier;
begin
  id := eof_t; -- dummy
  if identifiers( token ).kind /= new_t then
     if token = number_t then
        err( optional_bold( "identifier") & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = word_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "(shell immediate) word" ) );
     elsif token = eof_t then
        err( optional_bold( "identifier" ) & " expected" );
     elsif is_keyword( token ) then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif identifiers( token ).field_of /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "field of a record type" ) );
     else
        -- an existing token name
        fieldName := identifiers( record_id ).name & "." & identifiers( token ).name;
        findIdent( fieldName, temp_id );
        if temp_id /= eof_t then
           err( "already declared " &
                optional_bold( to_string( fieldName ) ) );
        else                                                     -- declare it
           declareIdent( id, fieldName, new_t, otherClass );
        end if;
     end if;
     getNextToken;
  else
     -- a new token
     fieldName := identifiers( record_id ).name & "." & identifiers( token ).name;
     findIdent( fieldName, temp_id );
     if temp_id /= eof_t then
        err( "already declared " &
             optional_bold( to_string( fieldName ) ) );
     else                                                     -- declare it
        discardUnusedIdentifier( token );
        declareIdent( id, fieldName, new_t, otherClass );
     end if;
     getNextToken;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
end ParseFieldIdentifier;

procedure ParseProcedureIdentifier( id : out identifier ) is
  -- Expect a new identifier, or one declared in this scope, but
  -- if one from another scope it will need to be redeclared in
  -- this scope.  Use this for procedure names that might possibly
  -- be declared "forward".
  -- Also used for record field variables where the variables may
  -- be declared in a different scope.
begin
  id := eof_t; -- dummy
  if identifiers( token ).kind /= new_t then
     if token = number_t then
        err( optional_bold( "identifier") & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = word_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "(shell immediate) word" ) );
     elsif token = eof_t then
        err( optional_bold( "identifier" ) & " expected" );
     elsif is_keyword( token ) then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif identifiers( token ).field_of /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "field of a record type" ) );
     -- if old, don't redeclare if it was a forward declaration
     elsif identifiers( token ).class = userProcClass then       -- a proc?
        if isLocal( token ) then                                 -- local?
           if length( identifiers( token ).value ) = 0 then      -- forward?
              id := token;                                       -- then it's
           else                                                  -- not fwd?
              err( "already declared " &
                   optional_bold( to_string( identifiers( token ).name ) ) );
           end if;                                               -- not local?
        else                                                     -- declare it
           declareIdent( id, identifiers( token ).name, identifiers( token ).kind,
           identifiers( token ).class);
        end if;                                                  -- otherwise
     elsif isLocal( token ) then
        err( "already declared " &
             optional_bold( to_string( identifiers( token ).name ) ) );
     else
        -- create a new one in this scope
        declareIdent( id, identifiers( token ).name, identifiers( token ).kind,
        identifiers( token ).class);
     end if;
     getNextToken;
  else
     id := token;
     getNextToken;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
end ParseProcedureIdentifier;

procedure ParseNewIdentifier( id : out identifier ) is
  -- expect a token that is a new, not previously declared identifier
  -- or one previously declared in a different scope that must be re-declared
  -- in this scope
begin
  id := eof_t; -- dummy
  if identifiers( token ).kind /= new_t then
     if token = number_t then
        err( optional_bold( "identifier") & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif token = word_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "(shell immediate) word" ) );
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "character literal" ) );
     elsif is_keyword( token ) and token /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif isLocal( token ) then
        err( "already declared " &
             optional_bold( to_string( identifiers( token ).name ) ) );
     else
        -- create a new one in this scope
        declareIdent( id, identifiers( token ).name, new_t, otherClass );
     end if;
     getNextToken;
  else
     id := token;
     getNextToken;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
end ParseNewIdentifier;

procedure ParseIdentifier( id : out identifier ) is
  -- expect a  previously declared identifier
begin
  id := eof_t; -- assume failure
  if token = number_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "number" ) );
  elsif token = strlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "string literal" ) );
  elsif token = backlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "backquoted literal" ) );
  elsif token = charlit_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "character literal" ) );
  elsif token = word_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "(shell immediate) word" ) );
  elsif is_keyword( token ) and token /= eof_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "keyword" ) );
  elsif token = symbol_t then
     err( optional_bold( "identifier" ) & " expected, not a " &
          optional_bold( "symbol" ) );
  elsif identifiers( token ).kind = new_t or identifiers( token ).deleted then
     -- if we're skipping a block, it doesn't matter if the identifier is
     -- declared, but it does if we're executing a block or checking syntax
     if isExecutingCommand or syntax_check then
        for i in identifiers'first..identifiers_top-1 loop
            if i /= token and not identifiers(i).deleted then
               if typoOf( identifiers(i).name, identifiers(token).name ) then
                  discardUnusedIdentifier( token );
                  err( optional_bold( to_string( identifiers(token).name ) ) &
                  " is a possible typo of " &
                  optional_bold( to_string( identifiers(i).name ) ) );
                  exit;
               end if;
           end if;
       end loop;
       if not error_found then
          -- token will be eof_t if error has already occurred
          discardUnusedIdentifier( token );
          err( optional_bold( to_string( identifiers( token ).name ) ) & " not declared" );
       end if;
     end if;
     -- this only appears if err in typo loop didn't occur
     --if not error_found then
     --   discardUnusedIdentifier( token );
     --end if;
  else
     id := token;
  end if;
  getNextToken;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
end ParseIdentifier;

-- Parameters

procedure ParseOutParameter( ref : out reference; defaultType : identifier ) is
  -- syntax: identifier [ (index) ]
  -- Parse an "out" parameter for a procedure call.  Return a reference
  -- to it.  If the variable being referenced doesn't exist, declare it
  -- (if the pragmas allow it).
  expr_kind : identifier;
  expr_value : unbounded_string;
  array_id2 : arrayID;
  arrayIndex: long_integer;
begin
  if identifiers( token ).kind = new_t and not onlyAda95 and not restriction_no_auto_declarations and not error_found and (inputMode = interactive or inputMode = breakout) then
     ParseNewIdentifier( ref.id );
     identifiers( ref.id ).kind := defaultType;
     identifiers( ref.id ).class := otherClass;
     put_trace( "Assuming " & to_string( identifiers( ref.id ).name ) &
         " is a new " & to_string( identifiers( defaultType ).name ) &
         " variable" );
  else
     ParseIdentifier( ref.id );
  end if;
  ref.index := 0;
  if identifiers( ref.id ).list then        -- array variable?
     ref.kind := identifiers( identifiers( ref.id ).kind ).kind;
     expect( symbol_t, "(" );
     ParseExpression( expr_value, expr_kind );
     if getUniType( expr_kind ) = uni_string_t or   -- index must be scalar
        identifiers( getBaseType( expr_kind ) ).list then
        err( "array index must be a scalar type" );
     end if;                                   -- variables are not
     if isExecutingCommand then                -- declared in syntax chk
         begin
            arrayIndex := long_integer(to_numeric(expr_value));-- convert to number
         exception when others =>
            err( "exception raised" );
            arrayIndex := 0;
         end;
         array_id2 := arrayID( to_numeric(      -- array_id2=reference
           identifiers( ref.id ).value ) );     -- to the array table
         if indexTypeOK( array_id2, expr_kind ) then -- check and access array
            if inBounds( array_id2, arrayIndex ) then
                ref.a_id  := array_id2;
                ref.index := arrayIndex;
            end if;
         end if;
      end if;
      expect( symbol_t, ")" );
  elsif identifiers( getBaseType( identifiers( ref.id ).kind ) ).kind = root_record_t then
  --      getBaseType( ref.kind ) = root_record_t then        -- record variable?
  -- To do this, search for the i-th field in the formal record declaration
  -- (the identifier value for the field has the field number).  The field name
  -- contains the full dot qualified name.  Get the base field name by removing
  -- everything except the name after the final dot.  Then prefix the name of
  -- the record being declared (so that "rec_type.f" becomes "my_rec.f").

     -- ref.kind := identifiers( identifiers( ref.id ).kind ).kind;
     ref.kind := identifiers( ref.id ).kind;
     for i in 1..integer'value( to_string( identifiers( ref.kind ).value ) ) loop         for j in 1..identifiers_top-1 loop
             if identifiers( j ).field_of = ref.kind then
                if integer'value( to_string( identifiers( j ).value )) = i then
                   declare
                      fieldName   : unbounded_string;
                      dont_care_t : identifier;
                      dotPos      : natural;
                   begin
                      fieldName := identifiers( j ).name;
                      dotPos := length( fieldName );
                      while dotPos > 1 loop
                         exit when element( fieldName, dotPos ) = '.';
                         dotPos := dotPos - 1;
                      end loop;
                      fieldName := delete( fieldName, 1, dotPos );
                      fieldName := identifiers( ref.id ).name & "." & fieldName;
                      declareIdent( dont_care_t, fieldName, identifiers( j ).kind, otherClass );
                   end;
                end if;
             end if;
         end loop;
     end loop;
  else
     ref.kind := identifiers( ref.id ).kind;
  end if;
end ParseOutParameter;

procedure ParseInOutParameter( ref : out reference ) is
  -- syntax: identifier [ (index) ]
  -- Parse an "in out" parameter for a procedure call.  Return a reference
  -- to it.  The variable being referenced must already exist.
  expr_kind : identifier;
  expr_value : unbounded_string;
  array_id2 : arrayID;
  arrayIndex: long_integer;
begin
  ParseIdentifier( ref.id );
  ref.index := 0;
  if identifiers( token ).list then        -- array variable?
     expect( symbol_t, "(" );
     ParseExpression( expr_value, expr_kind );
     expect( symbol_t, ")");
  end if;
  ref.index := 0;
  if identifiers( ref.id ).list then        -- array variable?
     ref.kind := identifiers( identifiers( ref.id ).kind ).kind;
     expect( symbol_t, "(" );
     ParseExpression( expr_value, expr_kind );
     if getUniType( expr_kind ) = uni_string_t or   -- index must be scalar
        identifiers( getBaseType( expr_kind ) ).list then
        err( "array index must be a scalar type" );
     end if;                                   -- variables are not
     if isExecutingCommand then                -- declared in syntax chk
         begin
            arrayIndex := long_integer(to_numeric(expr_value));-- convert to number
         exception when others =>
            err( "exception raised" );
            arrayIndex := 0;
         end;
         array_id2 := arrayID( to_numeric(      -- array_id2=reference
           identifiers( ref.id ).value ) );     -- to the array table
         if indexTypeOK( array_id2, expr_kind ) then -- check and access array
            if inBounds( array_id2, arrayIndex ) then
                ref.a_id  := array_id2;
                ref.index := arrayIndex;
            end if;
         end if;
      end if;
      expect( symbol_t, ")");
  elsif identifiers( getBaseType( identifiers( ref.id ).kind ) ).kind = root_record_t then
  -- To do this, search for the i-th field in the formal record declaration
  -- (the identifier value for the field has the field number).  The field name
  -- contains the full dot qualified name.  Get the base field name by removing
  -- everything except the name after the final dot.  Then prefix the name of
  -- the record being declared (so that "rec_type.f" becomes "my_rec.f").

     -- ref.kind := identifiers( identifiers( ref.id ).kind ).kind;
     ref.kind := identifiers( ref.id ).kind;
     for i in 1..integer'value( to_string( identifiers( ref.kind ).value ) ) loop         for j in 1..identifiers_top-1 loop
             if identifiers( j ).field_of = ref.kind then
                if integer'value( to_string( identifiers( j ).value )) = i then
                   declare
                      fieldName   : unbounded_string;
                      dont_care_t : identifier;
                      dotPos      : natural;
                   begin
                      fieldName := identifiers( j ).name;
                      dotPos := length( fieldName );
                      while dotPos > 1 loop
                         exit when element( fieldName, dotPos ) = '.';
                         dotPos := dotPos - 1;
                      end loop;
                      fieldName := delete( fieldName, 1, dotPos );
                      fieldName := identifiers( ref.id ).name & "." & fieldName;
                      declareIdent( dont_care_t, fieldName, identifiers( j ).kind, otherClass );
                   end;
                end if;
             end if;
         end loop;
     end loop;
  else
     ref.kind := identifiers( ref.id ).kind;
  end if;
end ParseInOutParameter;


-----------------------------------
-- Sound
-----------------------------------

procedure ParsePlay is
  expr_val  : unbounded_string;
  expr_type : identifier;
  pri_val   : unbounded_string := to_unbounded_string( integer'image( integer'last ) );
  pri_type  : identifier;
begin
  expect( sound_play_t );
  expect( symbol_t, "(" );
  ParseExpression( expr_val, expr_type );
  if uniTypesOK( expr_type, uni_string_t ) then
     if token = symbol_t and identifiers( token ).value = "," then
        expect( symbol_t, "," );
        ParseExpression( pri_val, pri_type );
        if uniTypesOK( pri_type, uni_numeric_t ) then
           null;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );
  if isExecutingCommand then
     begin
       Play( expr_val, integer( to_numeric( pri_val ) ) );
     exception when others =>
       err( "exception raised" );
     end;
  end if;
end ParsePlay;

procedure ParsePlayCD is
  dev_name : unbounded_string := null_unbounded_string;
  dev_kind : identifier;
begin
  expect( sound_playcd_t );
  if token = symbol_t and identifiers( token ).value = "(" then
     expect( symbol_t, "(" );
     ParseExpression( dev_name, dev_kind );
     if baseTypesOK( dev_kind, string_t ) then
        expect( symbol_t, ")" );
     end if;
  end if;
  if isExecutingCommand then
     PlayCD( dev_name );
  end if;
end ParsePlayCD;

procedure ParseStopCD is
begin
  expect( sound_stopcd_t );
  if isExecutingCommand then
     StopCD;
  end if;
end ParseStopCD;

procedure ParseMute is
begin
  expect( sound_mute_t );
  if isExecutingCommand then
     Mute;
  end if;
end ParseMute;

procedure ParseUnmute is
begin
  expect( sound_unmute_t );
  if isExecutingCommand then
     Unmute;
  end if;
end ParseUnmute;
-- this stuff should be in parser_sound.


-----------------------------------
-- Expressions
-----------------------------------

procedure DoUserDefinedFunction( s : unbounded_string; result : out unbounded_string );
-- forward declaration

procedure ParseFactor( f : out unbounded_string; kind : out identifier ) is
  -- Syntax: factor = (expr) | "strlit" | numeric-lit | identifier | built-in fn
  -- if the identifier is volatile, reload the value from the environment
  castType  : identifier;
  array_id  : identifier;
  array_id2 : arrayID;
  arrayIndex: long_integer;
  type aUniOp is ( noOp, doPlus, doMinus, doNot );
  uniOp : aUniOp := noOp;
  t : identifier;
begin
  if Token = symbol_t and identifiers( Token ).value = "+" then
     uniOp := doPlus;
     getNextToken;
  elsif Token = symbol_t and identifiers( Token ).value = "-" then
     uniOp := doMinus;
     getNextToken;
  elsif Token = not_t then
     uniOp := doNot;
     getNextToken;
  end if;
  if Token = symbol_t and then identifiers( Token ).value = "(" then
     expect( symbol_t, "(" );
     ParseExpression( f, kind );
     expect( symbol_t, ")" );
  else
     if Token = symbol_t and then identifiers( Token ).value = "$?" then
        f := to_unbounded_string( last_status'img );
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value = "$$" then
        f := to_unbounded_string( aPID'image( getpid ) );
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value = "$#" then
        if onlyAda95 then
           err( "$# not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        if isExecutingCommand then
           f := to_unbounded_string( integer'image( Argument_Count-optionOffset) );
        end if;
        kind := uni_numeric_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value >= "$1" and then
        identifiers( Token ).value <= "$9" then
        -- this could be done a little tighter (ie length check)
        if onlyAda95 then
           err( "$1..$9 not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        kind := uni_string_t;
        if isExecutingCommand then
           begin
              f := to_unbounded_string(
                 Argument(
                   integer'value(
                   "" & Element( identifiers( Token ).value, 2 ) )+optionOffset ) );
           exception when program_error =>
              err( "program_error exception raised" );
              kind := eof_t;
           when others =>
              err( "no such argument" );
              kind := eof_t;
           end;
        end if;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value = "$0" then
        if onlyAda95 then
           err( "$0 not allowed with " & optional_bold( "pragma ada_95" ) &
           " -- use command_line package" );
        end if;
        if isExecutingCommand then
           f := to_unbounded_string( Ada.Command_Line.Command_Name );
        end if;
        kind := uni_string_t;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value = "@" then
        if onlyAda95 then
           err( "@ is not allowed with " & optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        elsif itself_type = new_t then
           err( "@ is not defined" );
           f := null_unbounded_string;
           kind := eof_t;
        elsif identifiers( itself_type ).class = procClass then
           err( "@ is not a variable" );
        else
           f := itself;
           kind := itself_type;
        end if;
        getNextToken;
     elsif Token = symbol_t and then identifiers( Token ).value = "%" then
        if onlyAda95 then
           err( "% is not allowed with " & optional_bold( "pragma ada_95" ) );
           f := null_unbounded_string;
           kind := eof_t;
        elsif syntax_check then             -- % depends on run-time
           f := to_unbounded_string( "0" ); -- so just use a dummy
           kind := universal_t;             -- typeless value
        else
           if last_output_type = eof_t then
              err( "there has been no output assigned to %" );
           else
              f := last_output;
           end if;
           kind := last_output_type;
        end if;
        getNextToken;
     elsif token = number_t then                           -- numeric literal
        f := identifiers( token ).value;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = charlit_t then                          -- character literal
        --if length( identifiers( charlit_t ).value ) > 1 then
        --   err( "character literal more than 1 character" );
        --end if;
        f := identifiers( token ).value;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = strlit_t then                           -- string literal
        f := identifiers( token ).value;
        kind := identifiers( token ).kind;
        getNextToken;
     elsif token = backlit_t then           -- `cmds`
        kind := identifiers( token ).kind;
        CompileRunAndCaptureOutput( identifiers( token ).value, f );
        getNextToken;
     elsif token = get_line_t then                        -- get line function
        ParseGetLine( f );
        kind := universal_t;
     elsif token = inkey_t then                           -- inkey function
        ParseInkey( f );
        kind := character_t;
     elsif token = end_of_file_t then                     -- end_of_file function
        ParseEndOfFile( f );
        kind := boolean_t;
     elsif token = end_of_line_t then                     -- end_of_line function
        ParseEndOfLine( f );
        kind := boolean_t;
     elsif token = line_t then                            -- line function
        ParseLine( f );
        kind := integer_t;   -- probably should be something more specific
     elsif token = name_t then                            -- name function
        ParseName( f );
        kind := uni_string_t;
     elsif token = mode_t then                            -- mode function
        ParseMode( f );
        kind := file_mode_t;
     elsif token = is_open_t then                         -- is_open function
        ParseIsOpen( t );
        f := identifiers( t ).value;
        kind := boolean_t;
     elsif token = element_t then                         -- element function
        ParseStringsElement( f );
        kind := character_t;
     elsif token = slice_t then                           -- slice function
        ParseStringsSlice( f );
        kind := string_t;
     elsif token = index_t then                           -- index function
        ParseStringsIndex( f );
        kind := natural_t;
     elsif token = index_non_blank_t then                 -- index_non_blank function
        ParseStringsIndexNonBlank( f );
        kind := natural_t;
     elsif token = count_t then                           -- count function
        ParseStringsCount( f );
        kind := natural_t;
     elsif token = replace_slice_t then                   -- replace_slice function
        ParseStringsReplaceSlice( f );
        kind := string_t;
     elsif token = strings_insert_t then                  -- insert function
        ParseStringsInsert( f );
        kind := string_t;
     elsif token = overwrite_t then                       -- overwrite function
        ParseStringsOverwrite( f );
        kind := string_t;
     elsif token = sdelete_t then                         -- delete function
        ParseStringsDelete( f );
        kind := string_t;
     elsif token = trim_t then                            -- trim function
        ParseStringsTrim( f );
        kind := string_t;
     elsif token = length_t then                          -- trim function
        ParseStringsLength( f );
        kind := natural_t;
     elsif token = head_t then                            -- head function
        ParseStringsHead( f );
        kind := string_t;
     elsif token = tail_t then                            -- tail function
        ParseStringsTail( f );
        kind := string_t;
     elsif token = field_t then                           -- field function
        ParseStringsField( f );
        kind := string_t;
     elsif token = csv_field_t then                       -- csv_field function
        ParseStringsCSVField( f );
        kind := string_t;
     elsif token = lookup_t then                          -- lookup function
        ParseStringsLookup( f );
        kind := string_t;
     elsif token = to_upper_t then                        -- to_upper function
        ParseStringsToUpper( f, kind );
     elsif token = to_lower_t then                        -- to_lower function
        ParseStringsToLower( f, kind );
     elsif token = to_proper_t then                       -- to_proper function
        ParseStringsToProper( f, kind );
     elsif token = to_basic_t then                        -- to_basic function
        ParseStringsToBasic( f, kind );
     elsif token = to_escaped_t then                      -- to_escaped function
        ParseStringsToEscaped( f, kind );
     elsif token = mktemp_t then                          -- mktemp function
        ParseStringsMkTemp( f );
        kind := string_t;
     elsif token = unbounded_slice_t then                 -- unbounded_slice function
        ParseStringsUnboundedSlice( f );
        kind := unbounded_string_t;
     elsif token = val_t then                             -- val function
        ParseStringsVal( f );
        kind := character_t;
     elsif token = image_t then                           -- image function
        ParseStringsImage( f );
        kind := string_t;
     elsif token = glob_t then                            -- glob function
        ParseStringsGlob( f );
        kind := boolean_t;
     elsif token = match_t then                           -- match function
        ParseStringsMatch( f );
        kind := boolean_t;
     elsif token = tail_t then                            -- tail function
        ParseStringsTail( f );
        kind := string_t;
     elsif token = to_string_t then                       -- to_string function
        ParseStringsToString( f );
        kind := string_t;
     elsif token = to_u_string_t then          -- to_unbounded_string function
        ParseStringsToUString( f );
        kind := unbounded_string_t;
     elsif token = is_control_t then                     -- is_control function
        ParseStringsIsControl( f );
        kind := boolean_t;
     elsif token = is_graphic_t then                     -- is_graphic function
        ParseStringsIsGraphic( f );
        kind := boolean_t;
     elsif token = is_letter_t then                      -- is_letter function
        ParseStringsIsLetter( f );
        kind := boolean_t;
     elsif token = is_lower_t then                       -- is_lower function
        ParseStringsIsLower( f );
        kind := boolean_t;
     elsif token = is_upper_t then                       -- is_upper function
        ParseStringsIsUpper( f );
        kind := boolean_t;
     elsif token = is_basic_t then                       -- is_basic function
        ParseStringsIsBasic( f );
        kind := boolean_t;
     elsif token = is_digit_t then                       -- is_digit function
        ParseStringsIsDigit( f );
        kind := boolean_t;
     elsif token = is_hex_digit_t then                -- is_hex_digit function
        ParseStringsIsHexDigit( f );
        kind := boolean_t;
     elsif token = is_alphanumeric_t then           -- is_alphanumeric function
        ParseStringsIsAlphanumeric( f );
        kind := boolean_t;
     elsif token = is_special_t then                     -- is_special function
        ParseStringsIsSpecial( f );
        kind := boolean_t;
     elsif token = is_slashed_date_t then            -- is_slashed_date function
        ParseStringsIsSlashedDate( f );
        kind := boolean_t;
     elsif token = is_fixed_t then                       -- is_fixed function
        ParseStringsIsFixed( f );
        kind := boolean_t;
     elsif token = is_typo_of_t then                      -- is_typo_of function
        ParseStringsIsTypoOf( f );
        kind := boolean_t;
     elsif token = random_t then                          -- random function
        ParseNumericsRandom( f );
        kind := float_t;
     elsif token = shift_left_t then                      -- shift_left function
        ParseNumericsShiftLeft( f );
        kind := uni_numeric_t;
     elsif token = shift_right_t then                     -- shift_right function
        ParseNumericsShiftRight( f );
        kind := uni_numeric_t;
     elsif token = rotate_left_t then                     -- rotate_left function
        ParseNumericsRotateLeft( f );
        kind := uni_numeric_t;
     elsif token = rotate_right_t then                    -- rotate_right function
        ParseNumericsRotateRight( f );
        kind := uni_numeric_t;
     elsif token = shift_right_arith_t then               -- ASR function
        ParseNumericsASR( f );
        kind := uni_numeric_t;
     elsif token = abs_t then                             -- abs function
        ParseNumericsAbs( f );
        kind := uni_numeric_t;
     elsif token = sqrt_t then                            -- sqrt function
        ParseNumericsSqrt( f );
        kind := uni_numeric_t;
     elsif token = log_t then                             -- log function
        ParseNumericsLog( f );
        kind := uni_numeric_t;
     elsif token = exp_t then                             -- exp function
        ParseNumericsExp( f );
        kind := uni_numeric_t;
     elsif token = sin_t then                             -- sin function
        ParseNumericsSin( f );
        kind := uni_numeric_t;
     elsif token = cos_t then                             -- cos function
        ParseNumericsCos( f );
        kind := uni_numeric_t;
     elsif token = tan_t then                             -- tan function
        ParseNumericsTan( f );
        kind := uni_numeric_t;
     elsif token = cot_t then                             -- cot function
        ParseNumericsCot( f );
        kind := uni_numeric_t;
     elsif token = arcsin_t then                          -- arcsin function
        ParseNumericsArcSin( f );
        kind := uni_numeric_t;
     elsif token = arccos_t then                          -- arccos function
        ParseNumericsArcCos( f );
        kind := uni_numeric_t;
     elsif token = arctan_t then                          -- arctan function
        ParseNumericsArcTan( f );
        kind := uni_numeric_t;
     elsif token = arccot_t then                          -- arccot function
        ParseNumericsArcCot( f );
        kind := uni_numeric_t;
     elsif token = sinh_t then                            -- sinh function
        ParseNumericsSinH( f );
        kind := uni_numeric_t;
     elsif token = cosh_t then                            -- cosh function
        ParseNumericsCosH( f );
        kind := uni_numeric_t;
     elsif token = tanh_t then                            -- tanh function
        ParseNumericsTanH( f );
        kind := uni_numeric_t;
     elsif token = coth_t then                            -- coth function
        ParseNumericsCotH( f );
        kind := uni_numeric_t;
     elsif token = arcsinh_t then                         -- arcsinh function
        ParseNumericsArcSinH( f );
        kind := uni_numeric_t;
     elsif token = arccosh_t then                         -- arccosh function
        ParseNumericsArcCosH( f );
        kind := uni_numeric_t;
     elsif token = arctanh_t then                         -- arctanh function
        ParseNumericsArcTanH( f );
        kind := uni_numeric_t;
     elsif token = arccoth_t then                         -- arccoth function
        ParseNumericsArcCotH( f );
        kind := uni_numeric_t;
     elsif token = floor_t then                           -- floor function
        ParseNumericsFloor( f );
        kind := uni_numeric_t;
     elsif token = ceiling_t then                         -- ceiling function
        ParseNumericsCeiling( f );
        kind := uni_numeric_t;
     elsif token = rounding_t then                        -- rounding function
        ParseNumericsRounding( f );
        kind := uni_numeric_t;
     elsif token = unbiased_rounding_t then               -- unbiased rounding function
        ParseNumericsUnbiasedRounding( f );
        kind := uni_numeric_t;
     elsif token = truncation_t then                      -- truncation function
        ParseNumericsTruncation( f );
        kind := uni_numeric_t;
     elsif token = Remainder_t then                       -- remainder function
        ParseNumericsRemainder( f );
        kind := uni_numeric_t;
     elsif token = Exponent_t then                        -- exponent function
        ParseNumericsExponent( f );
        kind := uni_numeric_t;
     elsif token = Fraction_t then                        -- fraction function
        ParseNumericsFraction( f );
        kind := uni_numeric_t;
     elsif token = leading_part_t then                    -- leading part function
        ParseNumericsLeadingPart( f );
        kind := uni_numeric_t;
     elsif token = copy_sign_t then                       -- copy sign function
        ParseNumericsCopySign( f );
        kind := uni_numeric_t;
     elsif token = sturges_t then                         -- sturges function
        ParseNumericsSturges( f );
        kind := uni_numeric_t;
     elsif token = max_t then                             -- max function
        ParseNumericsMax( f );
        kind := uni_numeric_t;
     elsif token = min_t then                             -- min function
        ParseNumericsMin( f );
        kind := uni_numeric_t;
     elsif token = machine_t then                         -- machine function
        ParseNumericsMachine( f );
        kind := uni_numeric_t;
     elsif token = scaling_t then                         -- scaling function
        ParseNumericsScaling( f );
        kind := uni_numeric_t;
     elsif token = value_t then                           -- value function
        ParseNumericsValue( f );
        kind := uni_numeric_t;
     elsif token = pos_t then                             -- pos function
        ParseNumericsPos( f );
        kind := positive_t;
     elsif token = numerics_md5_t then                    -- md5 function
        ParseNumericsMd5( f );
        kind := string_t;
     elsif token = serial_t then                          -- serial function
        ParseNumericsSerial( f );
        kind := natural_t;
     elsif token = rnd_t then                             -- rnd function
        ParseNumericsRnd( f );
        kind := positive_t;
     elsif token = odd_t then                             -- odd function
        ParseNumericsOdd( f );
        kind := boolean_t;
     elsif token = even_t then                            -- even function
        ParseNumericsEven( f );
        kind := boolean_t;
     elsif token = numerics_re_t then                     -- complex re
        ParseNumericsRe( f );
        kind := long_float_t;
     elsif token = numerics_im_t then                     -- complex im
        ParseNumericsIm( f );
        kind := long_float_t;
     elsif token = numerics_modulus_t then                -- complex modulus
        ParseNumericsModulus( f );
        kind := long_float_t;
     elsif token = numerics_argument_t then               -- complex argument
        ParseNumericsArgument( f );
        kind := long_float_t;
     elsif token = source_info_symbol_table_size_t then   -- Symbol_Table_Sz
        getNextToken;
        if onlyAda95 then
           err( "symbol_table_size is not allowed with pragma ada_95" );
           f := null_unbounded_string;
           kind := eof_t;
        else
          f := delete( to_unbounded_string( identifier'image( identifiers_top-1 )), 1, 1 );
          kind := natural_t;
        end if;
     elsif token = source_info_file_t then                -- source_info.file
        f := basename( getSourceFileName );
        kind := string_t;
        getNextToken;
     elsif token = source_info_line_t then                -- source_info.line
        f := to_unbounded_string( getLineNo'img );
        kind := positive_t;
        getNextToken;
     elsif token = source_info_src_loc_t then      -- source_info.source_loc.
        f := to_unbounded_string( getLineNo'img );
        f := basename( getSourceFileName ) & ":" & f;
        kind := string_t;
        getNextToken;
     elsif token = source_info_enc_ent_t then      -- source_info.enclosing.
       if blocks_top > block'First then
          f := getBlockName( block'First );
       else
          f := to_unbounded_string( "script" );
       end if;
       kind := string_t;
        getNextToken;
     elsif token = cmd_argcount_t then
        ParseArgument_Count( f );
        kind := uni_numeric_t;
     elsif token = cmd_argument_t then
        ParseArgument( f );
        kind := uni_string_t;
     elsif token = cmd_commandname_t then
        ParseCommand_Name( f );
        kind := uni_string_t;
     elsif token = cmd_envcnt_t then
        ParseEnvironment_Count( f );
        kind := natural_t;
     elsif token = cmd_envval_t then
        ParseEnvironment_Value( f );
        kind := uni_string_t;
     elsif token = cgi_parsing_errors_t then               -- CGI package
        ParseParsing_Errors( f );
        kind := boolean_t;
     elsif token = cgi_input_received_t then               -- input_received
        ParseInput_Received( f );
        kind := boolean_t;
     elsif token = cgi_is_index_t then                     -- is_index
        ParseIs_Index( f );
        kind := boolean_t;
     elsif token = cgi_cgi_method_t then                   -- cgi_method
        ParseCGI_Method( f );
        kind := cgi_cgi_method_type_t;
     elsif token = cgi_value_t then                        -- value
        ParseValue( f );
        kind := string_t;
     elsif token = cgi_key_exists_t then                   -- key_exists
        ParseKey_Exists( f );
        kind := boolean_t;
     elsif token = cgi_key_count_t then                    -- key_count
        ParseKey_Count( f );
        kind := natural_t;
     elsif token = cgi_argument_count_t then               -- CGI.argument_cnt
        ParseCGIArgument_Count( f );
        kind := natural_t;
     elsif token = cgi_key_t then                          -- CGI.key
        ParseKey( f );
        kind := string_t;
     elsif token = cgi_key_value_t then                    -- CGI.key
        ParseKeyValue( f );
        kind := string_t;
     elsif token = cgi_key_value_exists_t then             -- CGI.key_val_exist
        ParseKey_Value_Exists( f );
        kind := boolean_t;
     elsif token = cgi_my_url_t then                       -- CGI.my_url
        ParseMy_URL( f );
        kind := string_t;
     elsif token = cgi_line_count_t then                   -- CGI.line_count
        ParseLine_Count( f );
        kind := natural_t;
     elsif token = cgi_line_count_of_value_t then          -- CGI.line_cnt_val
        ParseLine_Count_Of_Value( f );
        kind := natural_t;
     elsif token = cgi_line_t then                         -- CGI.line
        ParseCGILine( f );
        kind := string_t;
     elsif token = cgi_value_of_line_t then                -- CGI.Value_Of_Line
        ParseValue_Of_Line( f );
        kind := string_t;
     elsif token = cgi_url_decode_t then                   -- CGI.URL_Decode
        ParseURL_Decode( f );
        kind := string_t;
     elsif token = cgi_url_encode_t then                   -- CGI.URL_Encode
        ParseURL_Encode( f );
        kind := string_t;
     elsif token = cgi_html_encode_t then                  -- CGI.HTML_Encode
        ParseHTML_Encode( f );
        kind := string_t;
     elsif token = cgi_cookie_value_t then              -- CGI.Cooke_Value
        ParseCookie_Value( f );
        kind := string_t;
     elsif token = cgi_cookie_count_t then              -- CGI.Cooke_Count
        ParseCookie_Count( f );
        kind := natural_t;
     elsif token = cal_clock_t then                     -- Calendar.Clock
        ParseCalClock( f );
        kind := cal_time_t;
     elsif token = cal_year_t then                      -- Calendar.Year
        ParseCalYear( f );
        kind := cal_year_number_t;
     elsif token = cal_month_t then                     -- Calendar.Month
        ParseCalMonth( f );
        kind := cal_month_number_t;
     elsif token = cal_day_t then                       -- Calendar.Day
        ParseCalDay( f );
        kind := cal_day_number_t;
     elsif token = cal_seconds_t then                   -- Calendar.Seconds
        ParseCalSeconds( f );
        kind := cal_day_duration_t;
     elsif token = cal_time_of_t then                   -- Calendar.Time_Of
        ParseCalTimeOf( f );
        kind := cal_time_t;
     elsif token = cal_to_julian_t then                 -- Calendar.To_Julian
        ParseCalToJulian( f );
        kind := long_integer_t;
     elsif token = cal_to_time_t then                   -- Calendar.To_Time
        ParseCalToTime( f );
        kind := cal_time_t;
     elsif token = cal_day_of_week_t then               -- Calendar.Day_Of_Week
        ParseCalDayOfWeek( f );
        kind := integer_t;
     --elsif token = dbi_prepare_t then                  -- DB.Prepare
     --   ParseDBIPrepare( f );
     --   kind := boolean_t;
     elsif token = db_engine_of_t then                 -- DB.Engine_Of
        ParseDBEngineOf( f );
        kind := db_database_type_t;
     elsif token = db_is_connected_t then              -- DB.Is_Connected
        ParseDBIsConnected( f );
        kind := boolean_t;
     elsif token = db_error_message_t then             -- DB.Error_Message
        ParseDBErrorMessage( f );
        kind := string_t;
     elsif token = db_notice_message_t then            -- DB.Notice_Message
        ParseDBNoticeMessage( f );
        kind := string_t;
     elsif token = db_in_abort_state_t then            -- DB.In_Abort_State
        ParseDBInAbortState( f );
        kind := boolean_t;
     elsif token = db_options_t then                   -- DB.Options
        ParseDBOptions( f );
        kind := string_t;
     elsif token = db_will_rollback_on_finalize_t then -- DB.Will_Rollback_On_Finalize
        ParseDBWillRollbackOnFinalize( f );
        kind := boolean_t;
     elsif token = db_is_trace_t then                  -- DB.Is_Trace
        ParseDBIsTrace( f );
        kind := boolean_t;
     elsif token = db_end_of_query_t then              -- DB.End_Of_Query
        ParseDBEndOfQuery( f );
        kind := boolean_t;
     elsif token = db_tuple_t then                     -- DB.Tuple
        ParseDBTuple( f );
        kind := db_tuple_index_type_t;
     elsif token = db_tuples_t then                    -- DB.Tuples
        ParseDBTuples( f );
        kind := natural_t;
     elsif token = db_columns_t then                   -- DB.Columns
        ParseDBColumns( f );
        kind := natural_t;
     elsif token = db_column_name_t then               -- DB.Column_Name
        ParseDBColumnName( f );
        kind := string_t;
     elsif token = db_column_index_t then              -- DB.Column_Index
        ParseDBColumnIndex( f );
        kind := db_column_index_type_t;
     --elsif token = db_column_type_t then             -- DB.Column_Type
     --   ParseDBColumnType( f );
     --   kind := db_column_index_type_t;
     elsif token = db_is_null_t then                   -- DB.Is_Null
        ParseDBIsNull( f );
        kind := boolean_t;
     elsif token = db_value_t then                     -- DB.Value
        ParseDBValue( f );
        kind := universal_t;
     elsif token = mysql_engine_of_t then              -- MYSQL.Engine_Of
        ParseMySQLEngineOf( f );
        kind := db_database_type_t;
     elsif token = mysql_is_connected_t then           -- MYSQL.Is_Connected
        ParseMySQLIsConnected( f );
        kind := boolean_t;
     elsif token = mysql_error_message_t then          -- MYSQL.Error_Message
        ParseMySQLErrorMessage( f );
        kind := string_t;
     -- elsif token = mysql_notice_message_t then         -- MYSQL.Notice_Message
     --    ParseMySQLNoticeMessage( f );
     --    kind := string_t;
     elsif token = mysql_in_abort_state_t then         -- MYSQL.In_Abort_State
        ParseMySQLInAbortState( f );
        kind := boolean_t;
     elsif token = mysql_options_t then                -- MYSQL.Options
        ParseMySQLOptions( f );
        kind := string_t;
     elsif token = mysql_will_rollback_on_finalize_t then -- MYSQL.Will_Rollback_On_Finalize
        ParseMySQLWillRollbackOnFinalize( f );
        kind := boolean_t;
     elsif token = mysql_is_trace_t then               -- MYSQL.Is_Trace
        ParseMySQLIsTrace( f );
        kind := boolean_t;
     elsif token = mysql_end_of_query_t then           -- MYSQL.End_Of_Query
        ParseMySQLEndOfQuery( f );
        kind := boolean_t;
     elsif token = mysql_tuple_t then                  -- MYSQL.Tuple
        ParseMySQLTuple( f );
        kind := mysql_tuple_index_type_t;
     elsif token = mysql_tuples_t then                 -- MYSQL.Tuples
        ParseMySQLTuples( f );
        kind := natural_t;
     elsif token = mysql_columns_t then                -- MYSQL.Columns
        ParseMySQLColumns( f );
        kind := natural_t;
     elsif token = mysql_column_name_t then            -- MYSQL.Column_Name
        ParseMySQLColumnName( f );
        kind := string_t;
     elsif token = mysql_column_index_t then           -- MYSQL.Column_Index
        ParseMySQLColumnIndex( f );
        kind := mysql_column_index_type_t;
     --elsif token = db_column_type_t then             -- MYSQL.Column_Type
     --   ParseDBColumnType( f );
     --   kind := db_column_index_type_t;
     elsif token = mysql_is_null_t then                -- MYSQL.Is_Null
        ParseMySQLIsNull( f );
        kind := boolean_t;
     elsif token = mysql_value_t then                  -- MYSQL.Value
        ParseMySQLValue( f );
        kind := universal_t;
     elsif token = os_status_t then                    -- OS.status
        ParseOSSTatus( f );
        kind := integer_t;
     elsif token = units_inches2mm_t then               -- Units.Inches2MM
        ParseUnitsInches2MM( f );
        kind := long_float_t;
     elsif token = units_feet2cm_t then                 -- Units.Feet2CM
        ParseUnitsFeet2CM( f );
        kind := long_float_t;
     elsif token = units_yards2m_t then                 -- Units.Yards2M
        ParseUnitsYards2M( f );
        kind := long_float_t;
     elsif token = units_miles2km_t then                -- Units.Miles2KM
        ParseUnitsMiles2Km( f );
        kind := long_float_t;
     elsif token = units_mm2inches_t then               -- Units.MM2Inches
        ParseUnitsMM2Inches( f );
        kind := long_float_t;
     elsif token = units_cm2inches_t then               -- Units.CM2Inches
        ParseUnitsCM2Inches( f );
        kind := long_float_t;
     elsif token = units_m2yards_t then                 -- Units.M2Yards
        ParseUnitsM2Yards( f );
        kind := long_float_t;
     elsif token = units_km2miles_t then                -- Units.Km2Miles
        ParseUnitsKm2Miles( f );
        kind := long_float_t;
     elsif token = units_sqin2sqcm_t then               -- Units.SqIn2SqCm
        ParseUnitsSqIn2SqCm( f );
        kind := long_float_t;
     elsif token = units_sqft2sqm_t then                -- Units.SqFt2SqM
        ParseUnitsSqFt2SqM( f );
        kind := long_float_t;
     elsif token = units_sqyd2sqm_t then                -- Units.SqYd2SqM
        ParseUnitsSqYd2SqM( f );
        kind := long_float_t;
     elsif token = units_acres2hectares_t then          -- Units.Acres2Hectares
        ParseUnitsAcres2Hectares( f );
        kind := long_float_t;
     elsif token = units_sqcm2sqin_t then               -- Units.SqCm2SqIn
        ParseUnitsSqCm2SqIn( f );
        kind := long_float_t;
     elsif token = units_sqm2sqft_t then                -- Units.SqM2SqFt
        ParseUnitsSqM2SqFt( f );
        kind := long_float_t;
     elsif token = units_sqm2sqyd_t then                -- Units.SqM2SqYd
        ParseUnitsSqM2SqYd( f );
        kind := long_float_t;
     elsif token = units_sqkm2sqmiles_t then            -- Units.SqKm2SqM
        ParseUnitsSqKm2SqMiles( f );
        kind := long_float_t;
     elsif token = units_hectares2acres_t then          -- Units.Hectares2Acres
        ParseUnitsHectares2Acres( f );
        kind := long_float_t;
     elsif token = units_oz2grams_t then                -- Units.Oz2Grams
        ParseUnitsOz2Grams( f );
        kind := long_float_t;
     elsif token = units_lb2kg_t then                   -- Units.Lb2Kg
        ParseUnitsLb2Kg( f );
        kind := long_float_t;
     elsif token = units_tons2tonnes_t then             -- Units.Tons2Tonnes
        ParseUnitsTons2Tonnes( f );
        kind := long_float_t;
     elsif token = units_grams2oz_t then                -- Units.Grams2Oz
        ParseUnitsGrams2Oz( f );
        kind := long_float_t;
     elsif token = units_kg2lb_t then                   -- Units.Grams2Oz
        ParseUnitsKg2Lb( f );
        kind := long_float_t;
     elsif token = units_tonnes2tons_t then             -- Units.Tonnes2Tons
        ParseUnitsTonnes2Tons( f );
        kind := long_float_t;
     elsif token = units_ly2pc_t then                   -- Units.Ly2Pc
        ParseUnitsLy2Pc( f );
        kind := long_float_t;
     elsif token = units_pc2ly_t then                   -- Units.Pc2Ly
        ParseUnitsPc2Ly( f );
        kind := long_float_t;
     elsif token = units_floz2ml_t then                 -- Units.FlOz2Ml
        ParseUnitsFlOz2Ml( f );
        kind := long_float_t;
     elsif token = units_usfloz2ml_t then               -- Units.USFlOz2Ml
        ParseUnitsUSFlOz2Ml( f );
        kind := long_float_t;
     elsif token = units_usfloz2floz_t then             -- Units.USFlOz2FlOz
        ParseUnitsUSFlOz2FlOz( f );
        kind := long_float_t;
     elsif token = units_pints2l_t then                 -- Units.Pints2L
        ParseUnitsPints2L( f );
        kind := long_float_t;
     elsif token = units_gal2l_t then                   -- Units.Gal2L
        ParseUnitsGal2L( f );
        kind := long_float_t;
     elsif token = units_ml2floz_t then                 -- Units.Ml2FlOz
        ParseUnitsMl2FlOz( f );
        kind := long_float_t;
     elsif token = units_ml2usfloz_t then               -- Units.Ml2USFlOz
        ParseUnitsMl2USFlOz( f );
        kind := long_float_t;
     elsif token = units_floz2usfloz_t then             -- Units.FlOz2USFlOz
        ParseUnitsFlOz2USFlOz( f );
        kind := long_float_t;
     elsif token = units_usdrygal2l_t then              -- Units.USDryGal2L
        ParseUnitsUSDryGal2L( f );
        kind := long_float_t;
     elsif token = units_l2usdrygal_t then              -- Units.L2USDryGal
        ParseUnitsL2USDryGal( f );
        kind := long_float_t;
     elsif token = units_usliqgal2l_t then              -- Units.USDryLiq2L
        ParseUnitsUSLiqGal2L( f );
        kind := long_float_t;
     elsif token = units_l2usliqgal_t then              -- Units.L2USLiqGal
        ParseUnitsL2USLiqGal( f );
        kind := long_float_t;
     elsif token = units_troz2g_t then                  -- Units.Troz2G
        ParseUnitsTrOz2G( f );
        kind := long_float_t;
     elsif token = units_g2troz_t then                  -- Units.G2Troz
        ParseUnitsG2TrOz( f );
        kind := long_float_t;
     elsif token = units_cucm2floz_t then               -- Units.CuCm2Oz
        ParseUnitsCuCm2FlOz( f );
        kind := long_float_t;
     elsif token = units_floz2cucm_t then               -- Units.Oz2CuCm
        ParseUnitsFlOz2CuCm( f );
        kind := long_float_t;
     elsif token = units_cucm2usfloz_t then             -- Units.CuCm2USFlOz
        ParseUnitsCuCm2USFlOz( f );
        kind := long_float_t;
     elsif token = units_usfloz2cucm_t then             -- Units.USFlOz2CuCm
        ParseUnitsUSFlOz2CuCm( f );
        kind := long_float_t;
     elsif token = units_bytes2mb_t then                -- Units.Bytes2MB
        ParseUnitsBytes2MB( f );
        kind := long_float_t;
     elsif token = units_mb2bytes_t then                -- Units.MB2Bytes
        ParseUnitsMB2Bytes( f );
        kind := long_float_t;
     elsif token = units_l2quarts_t then                -- Units.L2Quarts
        ParseUnitsL2Quarts( f );
        kind := long_float_t;
     elsif token = units_l2gal_t then                   -- Units.L2Gal
        ParseUnitsL2Gal( f );
        kind := long_float_t;
     elsif token = units_f2c_t then                     -- Units.F2C
        ParseUnitsF2C( f );
        kind := long_float_t;
     elsif token = units_c2f_t then                     -- Units.C2F
        ParseUnitsC2F( f );
        kind := long_float_t;
     elsif token = units_k2c_t then                     -- Units.K2C
        ParseUnitsK2C( f );
        kind := long_float_t;
     elsif token = units_c2k_t then                     -- Units.C2K
        ParseUnitsC2K( f );
        kind := long_float_t;
     elsif token = files_exists_t then                -- files.file_exists
        ParseFileExists( f );
        kind := boolean_t;
     elsif token = files_is_absolute_path_t then      -- files.is_absolute_path
        ParseIsAbsolutePath( f );
        kind := boolean_t;
     elsif token = files_is_regular_file_t then       -- files.is_regular_file
        ParseIsRegularFile( f );
        kind := boolean_t;
     elsif token = files_is_directory_t then          -- files.is_directory
        ParseIsDirectory( f );
        kind := boolean_t;
     elsif token = files_is_writable_file_t then       -- files.is_writable_file
        ParseIsWritableFile( f );
        kind := boolean_t;
     elsif token = files_is_writable_t then            -- files.is_writable
        ParseIsWritable( f );
        kind := boolean_t;
     elsif token = files_is_executable_file_t then     -- files.is_executable_file
        ParseIsExecutableFile( f );
        kind := boolean_t;
     elsif token = files_is_executable_t then         -- files.is_executable
        ParseIsExecutable( f );
        kind := boolean_t;
     elsif token = files_is_readable_file_t then       -- files.is_readable_file
        ParseIsReadableFile( f );
        kind := boolean_t;
     elsif token = files_is_readable_t then            -- files.is_readable_file
        ParseIsReadable( f );
        kind := boolean_t;
     elsif token = files_basename_t then               -- files.basename
        ParseBasename( f );
        kind := string_t;
     elsif token = files_dirname_t then                -- files.dirname
        ParseDirname( f );
        kind := string_t;
     elsif token = files_size_t then                   -- files.size
        ParseFileSize( f );
        kind := long_integer_t;
     elsif token = files_is_waiting_file_t then        -- files.is_waiting_file
        ParseIsWaitingFile( f );
        kind := boolean_t;
     elsif token = files_last_modified_t then          -- files.last_modified
        ParseFileLastModified( f );
        kind := cal_time_t;
     elsif token = files_last_changed_t then           -- files.last_changed
        ParseFileLastChanged( f );
        kind := cal_time_t;
     elsif token = files_last_accessed_t then          -- files.last_accessed
        ParseFileLastAccessed( f );
        kind := cal_time_t;
     elsif token = dirops_dir_separator_t then         -- dir_opts.dir_separator
        ParseDirOpsDirSeparator( f );
        kind := character_t;
     elsif token = dirops_get_current_dir_t then       -- dir_opts.get_current_dir
        ParseDirOpsGetCurrentDir( f);
        kind := dirops_dir_name_str_t;
     elsif token = dirops_dir_name_t then              -- dir_opts.dir_name
        ParseDirOpsDirName( f );
        kind := dirops_dir_name_str_t;
     elsif token = dirops_base_name_t then             -- dir_opts.base_name
        ParseDirOpsBaseName( f );
        kind := string_t;
     elsif token = dirops_file_extension_t then        -- dir_opts.file_ext
        ParseDirOpsFileExtension( f );
        kind := string_t;
     elsif token = dirops_file_name_t then             -- dir_opts.file_name
        ParseDirOpsFileName( f );
        kind := string_t;
     elsif token = dirops_format_pathname_t then       -- dir_opts.format_p
        ParseDirOpsFormatPathname( f );
        kind := dirops_path_name_t;
     elsif token = dirops_expand_path_t then           -- dir_opts.expand_p
        ParseDirOpsExpandPath( f );
        kind := dirops_path_name_t;
     elsif token = arrays_first_t then                 -- arrays.first
        ParseArraysFirst( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = arrays_last_t then                  -- arrays.last
        ParseArraysLast( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = arrays_length_t then                 -- arrays.last
        ParseArraysLength( f );
        kind := natural_t;
     elsif token = enums_first_t then                  -- enums.first
        ParseEnumsFirst( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = enums_last_t then                   -- enums.last
        ParseEnumsLast( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = enums_prev_t then                   -- enums.prev
        ParseEnumsPrev( f, kind );
     elsif token = enums_succ_t then                   -- enums.succ
        ParseEnumsSucc( f, kind );
     elsif token = stats_average_t then                -- stats.average
        ParseStatsAverage( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = stats_max_t then                    -- stats.max
        ParseStatsMax( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = stats_min_t then                    -- stats.min
        ParseStatsMin( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = stats_standard_deviation_t then     -- stats.standard_deviation
        ParseStatsStandardDeviation( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = stats_sum_t then                    -- stats.sum
        ParseStatsSum( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = stats_variance_t then               -- stats.variance
        ParseStatsVariance( f, kind );
        if syntax_check then                           -- array index type
           kind := universal_t;                        -- not known at
        end if;                                        -- syntax check time
     elsif token = pen_is_empty_rect_t then            -- pen.is_empty_rect
        ParsePenIsEmptyRect( f );
        kind := boolean_t;
     elsif token = pen_inside_rect_t then              -- pen.inside_rect
        ParsePenInsideRect( f );
        kind := boolean_t;
     elsif token = pen_in_rect_t then                  -- pen.in_rect
        ParsePenInRect( f );
        kind := boolean_t;
     elsif token = pen_get_pen_mode_t then             -- pen.get_pen_mode
        ParsePenGetPenMode( f );
        kind := pen_pen_mode_t;
     elsif token = pen_greyscale_t then                -- pen.greyscale
        ParsePenGreyscale( f );
        kind := pen_rgbcomponent_t;
     elsif identifiers( token ).class = userFuncClass then
        declare
          funcToken : identifier := token;
        begin
          DoUserDefinedFunction( identifiers( funcToken ).value, f );
          kind := identifiers( funcToken ).kind;
        end;
     elsif identifiers( token ).kind = keyword_t then      -- no keywords
        f := null_unbounded_string;                        -- (always return something)
        kind := universal_t;
        err( "variable, value or expression expected" );
     else                                                  -- some kind of user ident?
        ParseIdentifier( t );
        if identifiers( t ).volatile then           -- volatile user identifier
           refreshVolatile( t );
           f := identifiers( t ).value;
           kind := identifiers( t ).kind;
        elsif identifiers( t ).class = subClass or             -- type cast
           identifiers( t ).class = typeClass then
           if identifiers( getBaseType( t ) ).list then        -- array cast?
              err( "cannot typecast by array types...perhaps you wanted an array variable" ); -- because we can't
           end if;                               -- represent array types
           castType := t;                        -- in expressiosn (yet)
           expect( symbol_t, "(" );
           ParseExpression( f, kind );
           expect( symbol_t, ")" );
           if uniTypesOk( castType, kind ) then
              kind := castType;
              if isExecutingCommand then
	         f := castToType( to_numeric( f ), kind );
              end if;
           end if;
        elsif identifiers( getBaseType( t ) ).list then        -- array(index)?
           array_id := t;                            -- array_id=array variable
           expect( symbol_t, "(" );                  -- parse index part
           ParseExpression( f, kind );               -- kind is the index type
           if getUniType( kind ) = uni_string_t or   -- index must be scalar
              identifiers( getBaseType( kind ) ).list then
              err( "array index must be a scalar type" );
           end if;                                   -- variables are not
           if isExecutingCommand then                -- declared in syntax chk
              arrayIndex := long_integer(to_numeric(f));  -- convert to number
              array_id2 := arrayID( to_numeric(      -- array_id2=reference
                 identifiers( array_id ).value ) );  -- to the array table
              if indexTypeOK( array_id2, kind ) then -- check and access array
                  if inBounds( array_id2, arrayIndex ) then
                     f := arrayElement( array_id2, arrayIndex );
                  end if;
              end if;
           end if;
           expect( symbol_t, ")" );                  -- element type is k's k
           kind := identifiers( identifiers( array_id ).kind ).kind;
        else                                          -- user identifier
           f := identifiers( t ).value;
           kind := identifiers( t ).kind;
        end if;
     end if;
  end if;
  case uniOp is
  when noOp => null;
  when doPlus =>
       if baseTypesOk( kind, uni_numeric_t ) then
          null;
       end if;
  when doMinus =>
       begin
          if baseTypesOk( kind, uni_numeric_t ) then
             if isExecutingCommand then
                f := to_unbounded_string( -to_numeric( f ) );
             end if;
          end if;
       exception when others =>
          err( "exception raised" );
       end;
  when doNot =>
       begin
          if baseTypesOk( kind, boolean_t ) then
             if isExecutingCommand then
                if to_numeric( f ) = 1.0 then
                   f := to_unbounded_string( "0" );
                else
                   f := to_unbounded_string( "1" );
                end if;
             end if;
          end if;
       exception when others =>
          err( "exception raised" );
       end;
  when others =>
      err( "unexpected uniary operation error" );
  end case;
end ParseFactor;

procedure ParsePowerTermOperator( op : out unbounded_string ) is
-- Syntax: termop = "**"
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value /= "**" then
     err( "** operator expected");
  else
     op := identifiers( token ).value;
  end if;
  getNextToken;
end ParsePowerTermOperator;

procedure ParsePowerTerm( term : out unbounded_string; term_type : out identifier ) is
  -- Syntax: term = "factor powerterm-op factor"
  factor1  : unbounded_string;
  factor2  : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
begin
  ParseFactor( factor1, kind1 );
  term := factor1;
  term_type := kind1;
  while identifiers( Token ).value = "**" loop
     ParsePowerTermOperator( operator );
     ParseFactor( factor2, kind2 );
     if baseTypesOk( kind1, kind2 ) then
        term_type := getBaseType( kind1 );
        operation := getUniType( kind1 );
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t then
           if operator = "**" then
              begin
                 if isExecutingCommand then
                    term := to_unbounded_string(
                         to_numeric( term ) **
                         natural( to_numeric( factor2 ) ) );
                 end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 term := null_unbounded_string;
               when others =>
                 err( "exception raised" );
                 term := null_unbounded_string;
              end;
          else
              err( "interal error: unknown power operator" );
          end if;
        else
           err( "operation ** not defined for these types" );
        end if;
     end if;
  end loop;
end ParsePowerTerm;

procedure ParseTermOperator( op : out unbounded_string ) is
  -- Syntax: termop = '*' | '/' | '&'
begin
  -- token value is checked by parseTerm, but not token name
  if Token = mod_t or Token = rem_t then
     op := identifiers( token ).name;
  elsif Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value /= "*" and identifiers( Token ).value /= "/" and identifiers( Token ).value /= "&" then
     err( "term operator expected");
  else
     op := identifiers( token ).value;
  end if;
  getNextToken;
end ParseTermOperator;

procedure ParseTerm( term : out unbounded_string; term_type : out identifier ) is
  -- Syntax: term = "powerterm term-op powerterm"
  pterm1   : unbounded_string;
  pterm2   : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
begin
  ParsePowerTerm( pterm1, kind1 );
  term := pterm1;
  term_type := kind1;
  while identifiers( Token ).value = "*" or
        identifiers( Token ).value = "/" or
        identifiers( Token ).value = "&" or
        Token = mod_t or Token = rem_t loop
     ParseTermOperator( operator );
     ParsePowerTerm( pterm2, kind2 );
     term_type := getBaseType( kind2 );
     operation := getUniType( kind2 );
     if operation = universal_t then
        operation := getUniType( kind1 );
     end if;
     if operation = universal_t then
        operation := uni_string_t;
     end if;
     if operation = uni_numeric_t then
        if baseTypesOk( kind1, kind2 ) then
             if operator = "*" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        to_numeric( term ) *
                        to_numeric( pterm2 ),
		       term_type );
                  end if;
                 exception when program_error =>
                    err( "program_error exception raised" );
                    term := null_unbounded_string;
                 when others =>
                    err( "exception raised" );
                    term := null_unbounded_string;
                 end;
             elsif operator = "/" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        to_numeric( term ) /
                        to_numeric( pterm2 ),
		       term_type );
                  end if;
                 exception when program_error =>
                    err( "program_error exception raised" );
                    term := null_unbounded_string;
                 when others =>
                    err( "exception raised" );
                    term := null_unbounded_string;
                 end;
             elsif operator = "mod" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        --long_long_integer'image(
                        long_float(
                        long_long_integer( to_numeric( term ) ) mod
                        long_long_integer( to_numeric( pterm2 ) ) ),
		       term_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err( "exception raised" );
                   term := null_unbounded_string;
                end;
             elsif operator = "rem" then
                begin
                  if isExecutingCommand then
                     term := castToType(
                        --long_long_integer'image(
                        long_float(
                        long_long_integer( to_numeric( term ) ) rem
                        long_long_integer( to_numeric( pterm2 ) ) ),
		       term_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   term := null_unbounded_string;
                when others =>
                   err( "exception raised" );
                   term := null_unbounded_string;
                end;
             else
                err( "Internal error: unable to handle term operator" );
             end if;
           end if;
        elsif operation = uni_string_t then
           declare
             base1 : identifier := getBaseType( kind1 );
             base2 : identifier := getBaseType( kind2 );
             uni1  : identifier := getUniType( kind1 );
             uni2  : identifier := getUniType( kind2 );
           begin
              if operator = "&" then
                 if base1 = character_t and base2 = character_t then
                    kind1 := string_t;
                    kind2 := string_t;
                    term_type := string_t;
                 elsif base1 = character_t and uni2 = uni_string_t then
                    kind1 := kind2;
                 elsif uni1 = uni_string_t and base2 = character_t then
                    kind2 := kind1;
                    term_type := kind1;
                 end if;
                 if baseTypesOk( kind1, kind2 ) then
                    if isExecutingCommand then
                       term := term & pterm2;
                    end if;
                 end if;
              elsif operator = "*" then
                 if baseTypesOk( kind1, natural_t ) then
                    if baseTypesOk( kind2, uni_string_t ) then
                       if isExecutingCommand then
                          term := natural( to_numeric( term ) ) * pterm2;
                       end if;
                    end if;
                 end if;
              else
                 err( "operation not defined for string types" );
              end if;
           exception when program_error =>
              err( "program_error exception raised" );
              term := null_unbounded_string;
           when others =>
              err( "exception raised" );
              term := null_unbounded_string;
           end;
        else
           if operator = "*" then
              err( "operation * not defined for these types" );
           elsif operator = "/" then
              err( "operation / not defined for these types" );
           elsif operator = "&" then
              err( "operation & not defined for these types" );
           end if;
        end if;
  end loop;
end ParseTerm;

procedure ParseSimpleExpressionOperator( op : out unbounded_string ) is
  -- Syntax: simple-expr-op = '+' | '-'
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t then
     err( "operator expected");
  elsif identifiers( Token ).value /= "+" and identifiers( Token ).value /= "-" then
     err( "simple expression operator expected");
  end if;
  op := identifiers( token ).value;
  getNextToken;
end ParseSimpleExpressionOperator;

procedure ParseSimpleExpression( se : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: term = "term expr-op term"
  term1    : unbounded_string;
  term2    : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : unbounded_string;
  operation: identifier;
  typesOK  : boolean := false;
begin
  ParseTerm( term1, kind1 );
  se := term1;
  expr_type := kind1;
  while identifiers( Token ).value = "+" or identifiers( Token ).value = "-" loop
     ParseSimpleExpressionOperator( operator );
     ParseTerm( term2, kind2 );
     -- Special exception for + and -...allow time arithmetic
     if (kind1 = cal_time_t) and then (getBaseType(kind2) = duration_t or kind2 = uni_numeric_t or kind2 = universal_t) then
        typesOK := true;
        expr_type := cal_time_t;
        operation := uni_numeric_t;
     end if;
     if (kind2 = cal_time_t) and then (getBaseType(kind1) = duration_t or kind1 = uni_numeric_t or kind2 = universal_t) then
        typesOK := true;
        expr_type := cal_time_t;
        operation := uni_numeric_t;
     end if;
     -- Otherwise check the types normally
     if not typesOK then
        typesOK := baseTypesOk( kind1, kind2 );
        expr_type := getBaseType( kind1 );
        operation := getUniType( kind1 );
     end if;
     if typesOk then
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t then
             if operator = "+" then
                begin
                  if isExecutingCommand then
                     se := castToType(
                        to_numeric( se ) +
                        to_numeric( term2 ),
		       expr_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   se := null_unbounded_string;
                when others =>
                   err( "exception raised" );
                   se := null_unbounded_string;
                end;
             elsif operator = "-" then
                begin
                  if isExecutingCommand then
                     se := castToType(
                        to_numeric( se ) -
                        to_numeric( term2 ),
		       expr_type );
                  end if;
                exception when program_error =>
                   err( "program_error exception raised" );
                   se := null_unbounded_string;
                when others =>
                   err( "exception raised" );
                   se := null_unbounded_string;
                end;
             end if;
        else
             if operator = "+" then
                err( "operation + not defined for these types" );
             elsif operator = "-" then
                err( "operation - not defined for these types" );
             end if;
        end if;
     end if;
  end loop;
  --put_line( "Simple Expression value = " & to_string( se ) );
end ParseSimpleExpression;

procedure ParseRelationalOperator( op : out unbounded_string ) is
  -- Syntax: rel-op = >, >=, etc.
begin
  -- token value is checked by parseTerm, but not token name
  if Token /= symbol_t and Token /= in_t and Token /= not_t then
     err( "operator expected");
  elsif identifiers( Token ).value /= ">=" and
        identifiers( Token ).value /= ">" and
        identifiers( Token ).value /= "<" and
        identifiers( Token ).value /= "<=" and
        identifiers( Token ).value /= "=" and
        identifiers( Token ).value /= "/=" and
        Token /= in_t and Token /= not_t then
     err( "relational operator expected");
  end if;
  if Token = in_t then
     op := identifiers( token ).name;
  elsif Token = not_t then
     op := to_unbounded_string( "not in" );
     getNextToken;
     if Token /= in_t then
        err( "relational operator expected");
     end if;
  else
     op := identifiers( token ).value;
  end if;
  getNextToken;
end ParseRelationalOperator;

procedure ParseRelation( re : out unbounded_string; rel_type : out identifier ) is
  -- Syntax: relation = "simple-expr" =|>|<|... "simple-expr"
  se1      : unbounded_string;
  se2      : unbounded_string;
  se3      : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  kind3    : identifier;
  operator : unbounded_string;
  operation: identifier;
  b        : boolean;
begin
  ParseSimpleExpression( se1, kind1 );
  re := se1;
  rel_type := kind1;
  if identifiers( Token ).value = ">=" or
        identifiers( Token ).value = ">" or
        identifiers( Token ).value = "<" or
        identifiers( Token ).value = "<=" or
        identifiers( Token ).value = "=" or
        identifiers( Token ).value = "/=" or
        Token = in_t or Token = not_t then
     rel_type := boolean_t; -- always
     ParseRelationalOperator( operator );
     if operator = "in" or operator = "not in" then
        ParseFactor( se2, kind2 );
        if baseTypesOk( kind1, kind2 ) then -- redundant below but
           expect( symbol_t, ".." );        -- keeps error messages nice
           ParseFactor( se3, kind3 );       -- should probably restructure
           if baseTypesOk( kind2, kind3 ) then
              null;
           end if;
        end if;
     else
        ParseSimpleExpression( se2, kind2 );
     end if;
     if baseTypesOk( kind1, kind2 ) then
        operation := getUniType( kind1 );
        if operation = universal_t then
           operation := getUniType( kind2 );
        end if;
        if operation = universal_t then
           operation := uni_string_t;
        end if;
        if operation = uni_numeric_t or else operation = root_enumerated_t or else operation = cal_time_t then
             begin
               if operator = ">=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) >= to_numeric( se2 );
                  end if;
               elsif operator = ">" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) > to_numeric( se2 );
                  end if;
               elsif operator = "<" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) < to_numeric( se2 );
                  end if;
               elsif operator = "<=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) <= to_numeric( se2 );
                  end if;
               elsif operator = "=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) = to_numeric( se2 );
                  end if;
               elsif operator = "/=" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) /= to_numeric( se2 );
                  end if;
               elsif operator = "in" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) in to_numeric( se2 )..to_numeric( se3 );
                  end if;
               elsif operator = "not in" then
                  if isExecutingCommand then
                     b := to_numeric( se1 ) not in to_numeric( se2 )..to_numeric( se3 );
                  end if;
               else
                  err( "Internal error: couldn't handle relational operator" );
               end if;
               if b then
                  re := to_unbounded_string( "1" );
               else
                  re := to_unbounded_string( "0" );
               end if;
             exception when others =>
               err( "exception raised" );
             end;
        elsif operation = uni_string_t then
             if operator = ">=" then
                if isExecutingCommand then
                   b := se1 >= se2;
                end if;
             elsif operator = ">" then
                if isExecutingCommand then
                   b := se1 > se2;
                end if;
             elsif operator = "<" then
                if isExecutingCommand then
                   b := se1 < se2;
                end if;
             elsif operator = "<=" then
                if isExecutingCommand then
                   b := se1 <= se2;
                end if;
             elsif operator = "=" then
                if isExecutingCommand then
                   b := se1 = se2;
                end if;
             elsif operator = "/=" then
                if isExecutingCommand then
                   b := se1 /= se2;
                end if;
             elsif operator = "in" then
                if isExecutingCommand then
                   if length( se1 ) /= 1 or
                      length( se2 ) /= 1 or
                      length( se3 ) /= 1 then
                      err( "scalar type required for range" );
                   else
                      declare
                        c1 : character := element( se1, 1 );
                        c2 : character := element( se2, 1 );
                        c3 : character := element( se3, 1 );
                      begin
                        b := c1 in c2..c3;
                      exception when others =>
                        err( "exception raised" );
                      end;
                   end if;
                end if;
             elsif operator = "not in" then
                if isExecutingCommand then
                   if length( se1 ) /= 1 or
                      length( se2 ) /= 1 or
                      length( se3 ) /= 1 then
                      err( "scalar type required for range" );
                   else
                      declare
                        c1 : character := element( se1, 1 );
                        c2 : character := element( se2, 1 );
                        c3 : character := element( se3, 1 );
                      begin
                        b := c1 not in c2..c3;
                      exception when others =>
                        err( "exception raised" );
                      end;
                   end if;
                end if;
             else
                err( "Internal error: couldn't handle relational operator" );
             end if;
             if b then
                re := to_unbounded_string( "1" );
             else
                re := to_unbounded_string( "0" );
             end if;
        else
             err( "relational operation not defined for these types" );
        end if;
     end if;
  end if;
end ParseRelation;

procedure ParseExpressionOperator( op : out identifier ) is
  -- Syntax: expr-op = "and" | "or" | "xor"
begin
  if Token /= and_t and
     Token /= or_t and
     Token /= xor_t then
     err( "boolean operator expected");
  end if;
  op := Token;
  getNextToken;
end ParseExpressionOperator;

procedure ParseExpression( ex : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: expr = "relation" and|or|xor "relation"
  re1      : unbounded_string;
  re2      : unbounded_string;
  kind1    : identifier;
  kind2    : identifier;
  operator : identifier;
  last_op  : identifier := eof_t;
  b        : boolean;
  type bitwise_number is mod 2**64;
begin
  ParseRelation( re1, kind1 );
  ex := re1;
  expr_type := kind1;
  while Token = and_t or Token = or_t or Token = xor_t loop
     ParseExpressionOperator( operator );
     if onlyAda95 and then last_op /= eof_t and then last_op /= operator then
        err( "mixed boolean operators in expression not allowed with " &
              optional_bold( "pragam ada_95" ) & " - use parantheses" );
     end if;
     ParseRelation( re2, kind2 );
     if baseTypesOk( kind1, kind2 ) then
        if getUniType( kind1 ) = uni_numeric_t then
           expr_type := getBaseType( kind1 );
           if operator = and_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) and
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when others =>
                 err( "exception raised" );
                 re1 := null_unbounded_string;
              end;
           elsif operator = or_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) or
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when others =>
                 err( "exception raised" );
                 re1 := null_unbounded_string;
              end;
           elsif operator = xor_t then
              begin
                if isExecutingCommand then
                   re1 := to_unbounded_string(
                      long_float(
                      bitwise_number( to_numeric( re1 ) ) xor
                      bitwise_number( to_numeric( re2 ) ) ) );
                end if;
              exception when program_error =>
                 err( "program_error exception raised" );
                 re1 := null_unbounded_string;
              when others =>
                 err( "exception raised" );
                 re1 := null_unbounded_string;
              end;
           end if;
        elsif getBaseType( kind1 ) = boolean_t then
           expr_type := getBaseType( kind1 );
           if operator = and_t then
              if isExecutingCommand then
                 b := re1 = "1" and re2 = "1";
              end if;
           elsif operator= or_t then
              if isExecutingCommand then
                 b := re1 = "1" or re2 = "1";
              end if;
           elsif operator = xor_t then
              if isExecutingCommand then
                 b := re1 = "1" xor re2 = "1";
              end if;
           else
              err( "Internal error: unable to handle boolean operator" );
           end if;
           if b then
              re1 := to_unbounded_string( "1" );
           else
              re1 := to_unbounded_string( "0" );
           end if;
        else
           err( "boolean or number expected" );
        end if;
     end if;
     last_op := operator;
  end loop;
  ex := re1;
  --put_line( "Expression value = " & to_string( ex ) );
end ParseExpression;

procedure ParseAssignPart( expr_value : out unbounded_string; expr_type : out identifier ) is
  -- Syntax: assign-part = " := default_value_expression"
  -- return value and type for expression
begin
  expect( symbol_t, ":=" );
  ParseExpression( expr_value, expr_type );
end ParseAssignPart;

procedure ParseArrayAssignPart( array_id : identifier; array_id2: arrayID ) is
  -- Syntax: array-assign-part = " := ( expr, expr, ... )|second-array"
  -- others => and positional assignment not (yet) supported
  -- return value and type for expression
  expr_value : unbounded_string;
  expr_type  : identifier;
  arrayIndex : long_integer;
  lastIndex  : long_integer;
  second_array_id  : identifier;
  second_array_id2 : arrayID;
begin

  -- Note: Array ID will not be valid at syntax check time

  expect( symbol_t, ":=" );
  if token = symbol_t then                                     -- assign (..)?
     expect( symbol_t, "(" );                                  -- read constant
     if isExecutingCommand then
        arrayIndex := firstBound( array_id2 );                 -- low bound
        lastIndex  := lastBound( array_id2 );                  -- high bound
     end if;
     loop                                                      -- read values
       ParseExpression( expr_value, expr_type );               -- next element
       if isExecutingCommand then                              -- not on synchk
          if not inBounds( array_id2, arrayIndex ) then        -- in range? add
             err( "the array can only hold" &
                  optional_bold( lastIndex'img ) & " elements" );
          else
             assignElement( array_id2, arrayIndex, expr_value );
          end if;
       end if;
       if arrayIndex = long_integer'last then                  -- shound never
          err( "too large for BUSH to store" );                -- happen but
       else                                                    -- check anyway
          arrayIndex := arrayIndex+1;                          -- next element
       end if;                                                 -- stop on err
       exit when error_found or identifiers( token ).value /= ","; -- more?
       expect( symbol_t, "," );                                -- continue
     end loop;
     arrayIndex := arrayIndex - 1;                             -- last added
     if trace then
        put_trace(
            to_string( identifiers( array_id ).name ) & " := " &
            arrayIndex'img & "elements" );
     end if;
     if isExecutingCommand then                                -- not on synchk
        if arrayIndex < lastIndex then                         -- check sizes
           err( "array literal has " & optional_bold( arrayIndex'img ) &
                " elements but the array has" &
                optional_bold( lastIndex'img ) & " elements" );
        end if;
     end if;
     expect( symbol_t, ")" );
  else                                                         -- copying a
     ParseIdentifier( second_array_id );                       -- second array?
     if isExecutingCommand then
        if not class_ok( second_array_id, otherClass ) then    -- must be arr
           null;                                               -- and good type
        elsif baseTypesOK( identifiers( array_id ).kind, identifiers( second_array_id ).kind ) then
           arrayIndex := firstBound( array_id2 );              -- low bound
           lastIndex := lastBound( array_id2 );                -- high bound
           second_array_id2 := arrayID( to_numeric( identifiers( second_array_id ).value ) );
           for i in arrayIndex..lastIndex loop                 -- do the copy
               expr_value := arrayElement( second_array_id2, i );
               assignElement( array_id2, i, expr_value );
           end loop;
           if trace then
              put_trace(
                to_string( identifiers( array_id ).name ) & " := " &
                to_string( identifiers( second_array_id ).name ) );
           end if;
        end if;
     end if;
  end if;
  -- should have put trace here to show assignment results
end ParseArrayAssignPart;

procedure ParseAnonymousArray( id : identifier ) is
  -- Syntax: anon-array = " array(expr..expr) of ident [array-assn]
  -- ParseDeclarationPart was getting complicated so this procedure
  -- was declared separatly.
  array_id    : arrayID;           -- array table index for array variable
  type_id     : arrayID;           -- array table index for anon array type
  ab1         : unbounded_string;  -- first array bound
  kind1       : identifier;        -- type of first array bound
  ab2         : unbounded_string;  -- last array bound
  kind2       : identifier;        -- type of last array bound
  elementType : identifier;        -- array elements type
  elementBaseType : identifier;        -- base type of array elements type
  anonType    : identifier;        -- identifier for anonymous array type
begin

  -- To create an anonymous array, we have to add a fake array type
  -- called "an anonymous array" to the symbol table and array table.

  expect( array_t );
  expect( symbol_t, "(" );
  ParseExpression( ab1, kind1 );                           -- low bound
  -- should really be a constant expression but we can't handle that
  if getUniType( kind1 ) = uni_string_t or                 -- must be scalar
      identifiers( getBaseType( kind1 ) ).list then
      err( "array indexes must be scalar types" );
  end if;
  expect( symbol_t, ".." );
  ParseExpression( ab2, kind2 );                            -- high bound
  if token = symbol_t and identifiers( token ).value = "," then
     err( "array of arrays not yet supported" );
  elsif baseTypesOk(kind1, kind2 ) then                     -- indexes good?
     if isExecutingCommand then                             -- not on synchk
        if to_numeric( ab1 ) > to_numeric( ab2 ) then       -- bound backwd?
           if long_integer( to_numeric( ab1 ) ) /= 1 and    -- only 1..0
              long_integer( to_numeric( ab2 ) ) /= 0 then   -- allowed
              err( "first array bound is higher than last array bound" );
           end if;
        end if;
     end if;
  end if;
  expect( symbol_t, ")" );                                  -- finished ind
  expect( of_t );
  ParseIdentifier( elementType );

  -- Declare anonymous type in symbol table and array table
  --
  -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

  if not error_found then     -- syntax OK, but if execution failed, no
     elementBaseType := getBaseType( elementType );
     if identifiers( elementBaseType ).list  then
        err( "array of arrays not yet supported" );
     else
        declareIdent( anonType, to_unbounded_string( "an anonymous array" ),
           elementType, typeClass );
        identifiers( anonType ).list := true;
        if class_ok( elementType, typeClass, subClass ) then     -- item type OK?
           --if isExecutingCommand then
           if isExecutingCommand and not syntax_check then
              declareArrayType( id => type_id,
                         name => to_unbounded_string( "an anonymous array" ),
                         first => long_integer( to_numeric( ab1 ) ),
                         last => long_integer( to_numeric( ab2 ) ),
                         ind => kind1,
                         blocklvl => blocks_top );
              identifiers( anonType ).value := to_unbounded_string( type_id'img );
           end if;
        end if;
     end if;
  end if;

  -- Declare array variable in array table
  --
  -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

  if isExecutingCommand then
     declareArray( id => array_id,
                   name => identifiers( id ).value,
                   first => long_integer( to_numeric( ab1 ) ),
                   last => long_integer( to_numeric( ab2 ) ),
                   ind => kind1,
                   blocklvl => blocks_top );
     identifiers( id ).value := to_unbounded_string( array_id'img );
  end if;

  -- Change variable into an array

  if not error_found then     -- syntax OK, but if execution failed, no
     identifiers( id ).list := true;                           -- var is an array
     identifiers( id ).kind := anonType;
  end if;

  -- Any initial assignment?  Then do it.
  --
  -- Note: Array ID will not be valid at syntax check time

  if token = symbol_t and identifiers( token ).value = ":=" then
     ParseArrayAssignPart( id, array_id );
  end if;

end ParseAnonymousArray;

procedure ParseArrayDeclaration( id : identifier; arrayType : identifier ) is
  -- Syntax: array-declaration = " := array_assign"
  -- ParseDeclarationPart was getting complicated so this procedure
  -- was declared separatly.
  array_id : arrayID;
  type_id : arrayID;
begin

  -- ParseDeclarationPart detected an array type, so let's set up the
  -- array variable.
  --
  -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

  if isExecutingCommand then
     type_id := arrayID( to_numeric( identifiers(
        getBaseType( arrayType ) ).value ) );
     declareArray( id => array_id,
                   name => identifiers( id ).value,
                   first => firstBound( type_id ),
                   last => lastBound( type_id ),
                   ind => indexType( type_id ),
                   blocklvl => blocks_top );
     identifiers( id ).value := to_unbounded_string( array_id'img );
  end if;

  -- Change variable into an array

  identifiers( id ).list := true;                           -- var is an array
  identifiers( id ).kind := arrayType;

  -- Any initial assignment?  Then do it.
  --
  -- Note: Array ID will not be valid at syntax check time

  if token = symbol_t and identifiers( token ).value = ":=" then
     ParseArrayAssignPart( id, array_id );
  end if;

end ParseArrayDeclaration;

procedure ParseRecordAssignPart( id : identifier; recType : identifier ) is
  field_no : integer;
  expr_value : unbounded_string;
  expr_type  : identifier;
  found      : boolean;
  expected_fields : integer;
  second_record_id : identifier;
begin
  expect( symbol_t, ":=" );
  if token = symbol_t then                                     -- assign (..)?
     expect( symbol_t, "(" );                                  -- read constant
     field_no := 1;
     begin
       expected_fields := integer'value( to_string( identifiers( recType ).value ) );
     exception when others =>
       expected_fields := 0;
     end;
     loop                                                      -- read values
       ParseExpression( expr_value, expr_type );               -- next element
       found := false;
       for j in 1..identifiers_top-1 loop
           if identifiers( j ).field_of = recType then
              if integer'value( to_string( identifiers( j ).value )) = field_no then
                 found := true;
                 declare
                    fieldName : unbounded_string;
                    field_t : identifier;
                 begin
                    fieldName := identifiers( j ).name;
                    fieldName := delete( fieldName, 1, index( fieldName, "." ) );
                    fieldName := identifiers( id ).name & "." & fieldName;
                    findIdent( fieldName, field_t );
                    if field_t = eof_t then
                       err( "unable to find record field " &
                          optional_bold( to_string( fieldName ) ) );
                    else
                       if baseTypesOK( identifiers( field_t ).kind, expr_type ) then
                          if isExecutingCommand then
                             identifiers( field_t ).value := expr_value;
                             if trace then
                                put_trace(
                                  to_string( fieldName ) & " := " &
                                  to_string( expr_value ) );
                             end if;
                          end if;
                       end if;
                    end if;
                 end;
           end if;
       end if;
       end loop; -- for
       if not found then
          err( "record literal too long" );
       end if;
       exit when error_found or identifiers( token ).value /= ","; -- more?
       expect( symbol_t, "," );
       field_no := field_no + 1;
     end loop;
     expect( symbol_t, ")" );
     if expected_fields /= field_no then
        err( "record literal too short" );
     end if;
  else
     ParseIdentifier( second_record_id );                      -- second rec?
     if isExecutingCommand then
        if not class_ok( second_record_id, otherClass ) then   -- must be rec
           null;                                               -- and good type
        elsif baseTypesOK( identifiers( id ).kind, identifiers( second_record_id ).kind ) then
           begin
             expected_fields := integer'value( to_string( identifiers( recType ).value ) );
           exception when others =>
             expected_fields := 0;
           end;
           declare
              sourceFieldName : unbounded_string;
              targetFieldName : unbounded_string;
              source_field_t : identifier;
              target_field_t : identifier;
           begin
              for field_no in 1..expected_fields loop
                 for j in 1..identifiers_top-1 loop
                     if identifiers( j ).field_of = recType then
                        if integer'value( to_string( identifiers( j ).value )) = field_no then
                           -- find source field
                           sourceFieldName := identifiers( j ).name;
                           sourceFieldName := delete( sourceFieldName, 1, index( sourceFieldName, "." ) );
                           sourceFieldName := identifiers( second_record_id ).name & "." & sourceFieldName;
                           findIdent( sourceFieldName, source_field_t );
                           if source_field_t = eof_t then
                              err( "internal error: mismatched source field" );
                              exit;
                           end if;
                           -- find target field
                           targetFieldName := identifiers( j ).name;
                           targetFieldName := delete( targetFieldName, 1, index( targetFieldName, "." ) );
                           targetFieldName := identifiers( id ).name & "." & targetFieldName;
                           findIdent( targetFieldName, target_field_t );
                           if target_field_t = eof_t then
                              err( "internal error: mismatched target field" );
                              exit;
                           end if;
                           -- copy it
                           identifiers( target_field_t ).value := identifiers( source_field_t ).value;
                           if trace then
                             put_trace(
                               to_string( targetFieldName ) & " := " &
                               to_string( identifiers( target_field_t ).value ) );
                           end if;
                        end if; -- right number
                     end if; -- field member
                 end loop; -- search loop
              end loop; -- fields
            end;
        end if;
     end if;
  end if;
end ParseRecordAssignPart;

procedure ParseRecordDeclaration( id : identifier; recType : identifier; canAssign : boolean := true ) is
  -- Syntax: rec-declaration = " := record_assign"
begin
  identifiers( id ).kind := recType;

  -- if isExecutingCommand then
  if not error_found then

  -- Change variable into an record
  -- Fill record value with ASCII.NUL delimited fields
  --
  -- To do this, search for the i-th field in the formal record declaration
  -- (the identifier value for the field has the field number).  The field name
  -- contains the full dot qualified name.  Get the base field name by removing
  -- everything except the name after the final dot.  Then prefix the name of
  -- the record being declared (so that "rec_type.f" becomes "my_rec.f").

     for i in 1..integer'value( to_string( identifiers( recType ).value ) ) loop
         for j in 1..identifiers_top-1 loop
             if identifiers( j ).field_of = recType then
                if integer'value( to_string( identifiers( j ).value )) = i then
                   declare
                      fieldName   : unbounded_string;
                      dont_care_t : identifier;
                      dotPos      : natural;
                   begin
                      fieldName := identifiers( j ).name;
                      dotPos := length( fieldName );
                      while dotPos > 1 loop
                         exit when element( fieldName, dotPos ) = '.';
                         dotPos := dotPos - 1;
                      end loop;
                      fieldName := delete( fieldName, 1, dotPos );
                      fieldName := identifiers( id ).name & "." & fieldName;
                      declareIdent( dont_care_t, fieldName, identifiers( j ).kind, otherClass );
                   end;
                end if;
             end if;
         end loop;
     end loop;

  end if;
  if token = symbol_t and identifiers( token ).value = ":=" then
     if canAssign then
        ParseRecordAssignPart( id, recType );
     end if;
  end if;

end ParseRecordDeclaration;

procedure ParseDeclarationPart( id : in out identifier; anon_arrays : boolean ) is
  -- Syntax: declaration = " : [aliased|constant] ident assign-part"
  -- Syntax: declaration = " : anonymous-array
  -- Syntax: declaration = " : array-declaration
  -- Syntax: declaration = " : record-declaration
  -- assigns type of identifier and value (if assignment part)
  -- Note: in some cases, the variable id may change.

  -- anon_arrays => actually, any nested structure allowed? for records

  type_token    : identifier;
  expr_value    : unbounded_string;
  expr_type     : identifier := eof_t;
  right_type    : identifier;
  expr_expected : boolean := false;
begin
  expect( symbol_t, ":" );

  if token = aliased_t then                            -- aliased not supported
     err( "aliased isn't supported" );
  elsif token = constant_t then                        -- handle constant
     expect( constant_t );                             -- by flagging variable
     identifiers( id ).class := constClass;            -- as a constant and
     expr_expected := true;                            -- must assign value
  else
     identifiers( id ).class := otherClass;            -- as a constant and
  end if;

  -- Anonymous Array?  Handled elsewhere.

  if token = array_t then                              -- anonymous array?
     if not anon_arrays then
        err( "anonymous arrays not allowed" );
     end if;
     ParseAnonymousArray( id );                        -- handle it
     return;                                           --  and nothing more
  end if;

  --  Get the type.

  ParseIdentifier( type_token );                       -- identify type

  -- Array type?  Handled elsewhere.

  if identifiers( getBaseType( type_token ) ).list then  -- array type?
     if not anon_arrays then
        err( "nested arrays not yet supported" );
     end if;
     ParseArrayDeclaration( id, type_token );          -- handle it
     return;                                           --  and nothing more
  end if;

  -- Record type?  Handled elsewhere.

  if identifiers( getBaseType( type_token ) ).kind = root_record_t then  -- record type?
     if not anon_arrays then
        err( "nested records not yet supported" );
     end if;
     ParseRecordDeclaration( id, type_token );          -- handle it
     return;                                           --  and nothing more
  end if;

  -- Verify that the type token is a type and check for types
  -- not allowed with certain pragmas.

  if not class_ok( type_token, typeClass, subClass ) then
     null;
  elsif onlyAda95 and (type_token = uni_string_t or type_token =
     uni_numeric_t or type_token = universal_t) then
     err( "universal/typeless types not allowed with " &
          optional_bold( "pragam ada_95" ) );
  elsif getBaseType( type_token ) = command_t then
     if onlyAda95 then
        err( "command types not allowed with " & optional_bold( "pragma ada_95" ) );
     elsif not expr_expected then
        err( "command variables must be constant" );
     end if;
  end if;

  -- Check for optional assignment

  if (token = symbol_t and identifiers( token ).value = ":=") or -- assign part?
     expr_expected then
     if identifiers( type_token ).limit then
        err( "limited type variables cannot be assigned a value" );
     end if;

     -- Tricky bit: what about "i : integer := i"?
     --   Dropping the top of the stack temporarily isn't good enough: if
     -- the assignment contains backquotes, the name of the command will
     -- overwrite the hidden variable.  The variable must be deleted and
     -- redeclared later.

     declare
        is_constant : boolean := false;
        var_name    : unbounded_string;
     begin

       -- Temporarily destroy identifer so that i : integer := i isn't circular

       var_name := identifiers( id ).name;                 -- remember name
       if identifiers( id ).class = constClass then        -- a constant?
          is_constant := true;                             -- remember it
       end if;
       discardUnusedIdentifier( id );                      -- discard variable

       -- Calculate the assignment (ie. using any previous variable i)

       ParseAssignPart( expr_value, right_type );          -- do := part

       -- Redeclare temporarily destroyed identifier (ie. declare new i)
       -- and assign its type

       declareIdent( id, var_name, type_token, otherClass ); -- declare var
       if is_constant then                                  -- a constant?
          identifiers( id ).class := constClass;            -- fix class
       end if;
     end;

     -- command types have special limitations

     if getBaseType( type_token ) = command_t then
        if baseTypesOk( uni_string_t, right_type ) then
           type_token := uni_string_t; -- pretend it's a string
           if not C_is_executable_file( to_string( expr_value ) & ASCII.NUL ) then
              err( '"' & to_string( expr_value) & '"' &
                 " is not an executable command" );
           end if;
        end if;
     elsif baseTypesOk( type_token, right_type ) then
        null;
     end if;
     if isExecutingCommand then
        if getUniType( type_token ) = uni_numeric_t then
           -- numeric test.  universal typelesses could result
           -- in a non-numeric expression that baseTypesOk
           -- doesn't catch.
           declare
              lf : long_float;
           begin
              lf := to_numeric( expr_value );
	      -- handle integer types
              expr_value := castToType( lf, type_token );
           exception when program_error =>
              err( "program_error exception raised" );
           when others =>
              err( "exception raised" );
           end;
        end if;
        identifiers( id ).value := expr_value;
        if trace then
            put_trace(
               to_string( identifiers( id ).name ) & " := """ &
               to_string( ToEscaped( expr_value ) ) & """" );
        end if;
      end if;
  else
     identifiers( id ).kind := type_token;
  end if;
  -- failed somewhere to set a real type?
  -- blow away half-declared variable
  if error_found then
     identifiers( id ).kind := new_t;
     discardUnusedIdentifier( id );
  end if;
end ParseDeclarationPart;

procedure ParsePragma is
  type aPragmaType is ( ada_95, asserting, annotate, debug, debug_on,
     depreciated, export, gcc_errors, import, inspection, inspect_var,
     noCommandHash, peek, promptChange, restriction, restriction_auto,
     restriction_external, template, unchecked_import, uninspect_var,
     unrestricted_template, volatile );
  pragmaKind  : aPragmaType;
  expr_val    : unbounded_string;
  results     : unbounded_string;
  var_id      : identifier;
  importType  : unbounded_string;
begin
  expect( pragma_t );
  if identifiers( token ).name = "ada_95" then
     pragmaKind := ada_95;
  elsif identifiers( token ).name = "assert" then
     pragmaKind :=  asserting;
  elsif identifiers( token ).name = "debug" then
     pragmaKind :=  debug;
  elsif identifiers( token ).name = "annotate" then
     pragmaKind :=  annotate;
  elsif identifiers( token ).name = "deprecated" then
     pragmaKind :=  depreciated;
  elsif identifiers( token ).name = "depreciated" then
     pragmaKind :=  depreciated;
  elsif identifiers( token ).name = "export" then
     pragmaKind := export;
  elsif identifiers( token ).name = "gcc_errors" then
     pragmaKind := gcc_errors;
  elsif identifiers( token ).name = "import" then
     pragmaKind := import;
  elsif identifiers( token ).name = "inspect" then
     pragmaKind := inspect_var;
  elsif identifiers( token ).name = "inspection_point" then
     pragmaKind := inspection;
  elsif identifiers( token ).name = "inspection_peek" then
     pragmaKind := peek;
  elsif identifiers( token ).name = "no_command_hash" then
     pragmaKind := noCommandHash;
  elsif identifiers( token ).name = "prompt_script" then
     pragmaKind := promptChange;
  elsif identifiers( token ).name = "restriction" then
     pragmaKind := restriction;
  elsif identifiers( token ).name = "restrictions" then
     discardUnusedIdentifier( token );
     err( "pragma restriction not restrictions" );
     return;
  elsif identifiers( token ).name = "template" then
     pragmaKind := template;
  elsif identifiers( token ).name = "unchecked_import" then
     pragmaKind := unchecked_import;
  elsif identifiers( token ).name = "uninspect" then
     pragmaKind := uninspect_var;
  elsif identifiers( token ).name = "unrestricted_template" then
     pragmaKind := unrestricted_template;
  elsif identifiers( token ).name = "volatile" then
     pragmaKind := volatile;
  else
     discardUnusedIdentifier( token );
     err( "unknown pragma" );
     return;
  end if;
  discardUnusedIdentifier( token );
  -- don't declare a new identifier for a pragma

  -- Parse the pragma parameters (if any)

  getNextToken;
  if pragmaKind /= ada_95 and pragmaKind /= inspection and pragmaKind /=
     noCommandHash and pragmaKind /= peek then
     if pragmaKind = debug and (token /= symbol_t or identifiers( token ).value /= "(") then
        pragmaKind := debug_on;
     else
        expect( symbol_t, "(" );
     end if;
  end if;

  case pragmaKind is
  when ada_95 =>                             -- pragma ada_95
     null;
  when asserting =>                          -- pragma assert
     ParseExpression( expr_val, var_id );
  when annotate =>                           -- pragma annotate
     if token /= strlit_t then
        if identifiers( token ).name /= "author" and
           identifiers( token ).name /= "created" and
           identifiers( token ).name /= "description" and
           identifiers( token ).name /= "errors" and
           identifiers( token ).name /= "modified" and
           identifiers( token ).name /= "param" and
           identifiers( token ).name /= "return" and
           identifiers( token ).name /= "see also" and
           identifiers( token ).name /= "summary" and
           identifiers( token ).name /= "version" then
           err( "unknown annotation field type" );
        else
           discardUnusedIdentifier( token );
           getNextToken;
           expect( symbol_t, "," );
        end if;
     end if;
     expr_val := identifiers( token ).value;
     expect( strlit_t );
  when debug =>                              -- pragma debug
     expr_val := identifiers( token ).value;
     expect( backlit_t );
  when debug_on =>                              -- pragma debug (no param)
     null;
  when depreciated =>                           -- pragma depreciated
     expr_val := identifiers( token ).value;
     expect( strlit_t );
  when export =>                                -- pragma export
     if identifiers( token ).name /= "shell" then
        discardUnusedIdentifier( token );
        err( "only 'shell' convention supported" );
        return;
     else
        discardUnusedIdentifier( token );
        getNextToken;
        expect( symbol_t, "," );
        ParseIdentifier( var_id );
     end if;
  when import | unchecked_import =>             -- pragma unchecked/import
     if identifiers( token ).name = "shell" then
        importType := identifiers( token ).name;
        discardUnusedIdentifier( token );
        getNextToken;
        expect( symbol_t, "," );
        ParseIdentifier( var_id );
     elsif identifiers( token ).name = "cgi" then
        importType := identifiers( token ).name;
        discardUnusedIdentifier( token );
        getNextToken;
        expect( symbol_t, "," );
        ParseIdentifier( var_id );
     else
        discardUnusedIdentifier( token );
        err( "only 'shell' or 'cgi' convention supported" );
        return;
     end if;
  when gcc_errors =>                         -- pragma gcc_errors
     null;
  when inspection =>                         -- pragma inspection point
     null;
  when peek =>                               -- pragma inspection peek
     null;
  when noCommandHash =>                      -- pragma no_command_hash
     null;
  when promptChange =>                       -- pragma prompt_script
     expr_val := identifiers( token ).value;
     expect( backlit_t );
  when restriction =>                        -- pragma restriction
     if identifiers( token ).name = "no_auto_declarations" then
        discardUnusedIdentifier( token );
        getNextToken;
        pragmaKind := restriction_auto;
     elsif identifiers( token ).name = "no_external_commands" then
        discardUnusedIdentifier( token );
        getNextToken;
        pragmaKind := restriction_external;
     else
        discardUnusedIdentifier( token );
        err( "unknown restriction" );
        return;
     end if;
  when inspect_var =>                        -- pragma inspect
     ParseIdentifier( var_id );
  when template | unrestricted_template =>   -- pragma (unrestricted) template
     if rshOpt then
        err( "templates are not allowed in a restricted shell" );
     else
        expr_val := identifiers( token ).name;
        discardUnusedIdentifier( token );
        getNextToken;
        if token = symbol_t and identifiers( token ).value = "," then
           expect( symbol_t, "," );
           expect( strlit_t );
        else
           var_id := eof_t;
        end if;
     end if;
     gccOpt := true;
  when uninspect_var =>                      -- pragma uninspect
     ParseIdentifier( var_id );
  when volatile =>                           -- pragma volatile
     ParseIdentifier( var_id );
  when others =>
     err( "Internal error: can't handle pragma" );
  end case;

  if pragmaKind /= ada_95 and pragmaKind /= inspection and pragmaKind /=
     noCommandHash and pragmaKind /= debug_on and pragmaKind /= peek then
     expect( symbol_t, ")" );
  end if;

  -- Execute the pragma

  if isExecutingCommand then
     case pragmaKind is
     when ada_95 =>
        onlyAda95 := true;
     when asserting =>
        if debugOpt then
           if not syntax_check then   -- has no meaning during syntax check
              if baseTypesOk( boolean_t, var_id ) then
                 if expr_val = "0" then
                    err( "assertion failed" );
                 end if;
              end if;
           end if;
        end if;
     when annotate =>
        null;
     when debug =>
        if debugOpt then
           if not syntax_check then
              declare
                 savershOpt : commandLineOption := rshOpt;
              begin
                 rshOpt := true;            -- force restricted shell mode
                 CompileRunAndCaptureOutput( expr_val, results );
                 rshOpt := savershOpt;
                 put( results );
              end;
           end if;
        end if;
     when debug_on =>
        debugOpt := true;
     when depreciated =>
        -- later, this should create a list of depreciation message
        -- for now, only the entire script is depreciated
        depreciatedMsg := "This script made obsolete by " & expr_val & '.';
     when export =>
        if identifiers( var_id ).class = userProcClass then
           err( "procedures cannot be exported to the shell environment" );
        elsif identifiers( var_id ).class = userFuncClass then
           err( "functions cannot be exported to the shell environment" );
        elsif identifiers( var_id ).list then
           err( "arrays cannot be exported to the shell environment" );
        elsif uniTypesOK( identifiers( var_id ).kind, uni_string_t ) then
           identifiers( var_id ).export := true;
        end if;
     when gcc_errors =>
        gccOpt := true;
     when import =>
        if identifiers( var_id ).class = userProcClass then
           err( "procedures cannot be imported" );
        elsif identifiers( var_id ).class = userFuncClass then
           err( "functions cannot be imported" );
        elsif identifiers( var_id ).list then
           err( "arrays cannot be imported" );
        elsif uniTypesOK( identifiers( var_id ).kind, uni_string_t ) then
           identifiers( var_id ).import := true;
           if processingTemplate and importType = "cgi" then
              identifiers( var_id ).value := null_unbounded_string;
              for i in 1..cgi.key_count( to_string( identifiers( var_id ).name ) ) loop
                  identifiers( var_id ).value := identifiers( var_id ).value &
                     to_unbounded_string( cgi.value( to_string( identifiers( var_id ).value ), 1, true ) );
               end loop;
           elsif not processingTemplate and importType = "cgi" then
               err( "import type cgi must be used in a template" );
           else
              refreshVolatile( var_id );
           end if;
           if trace then
               put_trace(
                  to_string( identifiers( var_id ).name ) & " := """ &
                  to_string( ToEscaped( identifiers( var_id ).value ) ) &
                  """" );
           end if;
        end if;
     when inspection =>
        if breakoutOpt then
           wasSIGINT := true;                            -- pretend ctrl-c
        end if;
     when peek =>
        for i in 1..identifiers_top-1 loop
            if identifiers( i ).inspect then
               Put_Identifier( i );
            end if;
        end loop;
        -- put_line( getStackTrace );
     when noCommandHash =>
        clearCommandHash;
        no_command_hash := true;
     when restriction_auto =>
        restriction_no_auto_declarations := true;
     when restriction_external =>
        restriction_no_external_commands := true;
     when promptChange =>
        promptScript := expr_val;
     when template | unrestricted_template =>
        templateType := noTemplate;
        if expr_val = "html" then
           templateType := htmlTemplate;
        elsif expr_val = "text" then
           templateType := textTemplate;
        else
           err( "unknown template type" );
        end if;
        if processingTemplate then
           err( "template already used" );
        elsif inputMode = interactive or inputMode = breakout then
           err( "template is not allowed in an interactive session" );
        end if;
        if var_id = eof_t  then
           templatePath := basename( scriptFilePath );
           if length( templatePath ) > 3 and then tail( templatePath, 3 ) = ".sp" then
              Delete( templatePath, length(templatePath)-2, length( templatePath ) );
           elsif length( templatePath ) > 5 and then tail( templatePath, 5 ) = ".bush" then
              Delete( templatePath, length(templatePath)-4, length( templatePath ) );
           elsif length( templatePath ) > 4 and then tail( templatePath, 4 ) = ".cgi" then
              Delete( templatePath, length(templatePath)-3, length( templatePath ) );
           end if;
           templatePath := templatePath & ".tmpl";
        else
           templatePath := identifiers( strlit_t ).value;
        end if;
        processingTemplate := true;
        if pragmaKind = unrestricted_template then
           unrestrictedTemplate := true;
        end if;
        -- Always output CGI header as soon as possible to avoid a HTTP/500
        -- error.  Give the web server a minimal header to return to the
        -- browser in case something goes wrong later that would prevent
        -- the header from being sent.
        if templateType = htmlTemplate then
           cgi.put_cgi_header( "Content-type: text/html" );
        elsif templateType = textTemplate then
           cgi.put_cgi_header( "Content-type: text/plain" );
        end if;
     when unchecked_import =>
        if uniTypesOK( identifiers( var_id ).kind, uni_string_t ) then
           if inEnvironment( var_id ) then
              identifiers( var_id ).import := true;
              if processingTemplate then
                 identifiers( var_id ).value := null_unbounded_string;
                 for i in 1..cgi.key_count( to_string( identifiers( var_id ).name ) ) loop
                     identifiers( var_id ).value := identifiers( var_id ).value &
                        to_unbounded_string( cgi.value( to_string( identifiers( var_id ).value ), 1, false) );
                  end loop;
              else
                 refreshVolatile( var_id );
              end if;
              if trace then
                  put_trace(
                     to_string( identifiers( var_id ).name ) & " := """ &
                     to_string( ToEscaped( identifiers( var_id ).value ) ) &
                     """" );
              end if;
           end if;
        end if;
     when inspect_var =>
        identifiers( var_id ).inspect := true;
     when uninspect_var =>
        identifiers( var_id ).inspect := false;
     when volatile =>
        identifiers( var_id ).volatile := true;
     when others =>
        err( "Internal error: unable to execute pragma" );
     end case;
  end if;
end ParsePragma;

procedure ParseRecordFields( record_id : identifier; field_no : in out integer ) is
-- Syntax: field = declaration [; declaration ... ]
   field_id : identifier;
   b : boolean;
begin
  -- ParseNewIdentifier( field_id );
  ParseFieldIdentifier( record_id, field_id );
  ParseDeclarationPart( field_id, anon_arrays => false );
  identifiers( field_id ).class := subClass;        -- it is a subtype
  identifiers( field_id ).field_of := record_id;    -- it is a field
  identifiers( field_id ).value := to_unbounded_string( field_no'img );
  expectSemicolon;
  if not error_found and  token /= eof_t and token /= end_t then
     field_no := field_no + 1;
     ParseRecordFields( record_id, field_no );
     -- the symbol table will overflow before field_no does
  end if;
  if error_found then
     b := deleteIdent( field_id );
  end if;
end ParseRecordFields;

procedure ParseRecordTypePart( newtype_id : identifier ) is
   -- Syntax: type = "record f1 : t1; ... end record"
   field_no : integer := 1;
   b : boolean;
begin
   expect( record_t );
   ParseRecordFields( newtype_id, field_no );
   expect( end_t );
   expect( record_t );
   -- if isExecutingCommand then
   if not error_found then
      identifiers( newtype_id ).kind := root_record_t;      -- a record
      identifiers( newtype_id ).list := false;              -- it isn't an array
      identifiers( newtype_id ).field_of := eof_t;          -- it isn't a field
      identifiers( newtype_id ).class := typeClass;         -- it is a type
      identifiers( newtype_id ).import := false;            -- never import
      identifiers( newtype_id ).export := false;            -- never export
      identifiers( newtype_id ).value := to_unbounded_string( field_no'img );
      -- number of fields in a record variable
   else                                                     -- otherwise
     b := deleteIdent( newtype_id );                        -- discard bad type
   end if;
end ParseRecordTypePart;

procedure ParseArrayTypePart( newtype_id : identifier ) is
   -- Syntax: type = "array(exp1..exp2) of element-type"
   type_id     : arrayID;
   ab1         : unbounded_string; -- low array bound
   kind1       : identifier;
   ab2         : unbounded_string; -- high array bound
   kind2       : identifier;
   elementType : identifier;
   elementBaseType : identifier;        -- base type of array elements type
   b           : boolean;
begin

   -- Check the Array Declaration

   expect( array_t );
   expect( symbol_t, "(" );
   ParseExpression( ab1, kind1 );
   -- should be constant expression but we can't handle those yet
   if getUniType( kind1 ) = uni_string_t or
      identifiers( kind1 ).list then
       err( "array indexes must be scalar types" );
   end if;
   expect( symbol_t, ".." );
   ParseExpression( ab2, kind2 );
   if token = symbol_t and identifiers( token ).value = "," then
      err( "array of arrays not yet supported" );
   elsif baseTypesOk(kind1, kind2 ) then
      if isExecutingCommand and not syntax_check then  -- ab1/2 undef on synchk
         if to_numeric( ab1 ) > to_numeric( ab2 ) then
            if long_integer( to_numeric( ab1 ) ) /= 1 and
               long_integer( to_numeric( ab2 ) ) /= 0 then
               err( "first array bound is higher than last array bound" );
            end if;
         end if;
      end if;
   end if;
   expect( symbol_t, ")" );
   expect( of_t );
   ParseIdentifier( elementType );                       -- parent type name

   -- Finish declaring the array
   --
   -- Note: Bounds are expressions and may not be defined during syntax check
  -- (Constant assignments, etc. occur only when actually running a script)

   elementBaseType := getBaseType( elementType );
   if identifiers( elementBaseType ).list  then
      err( "array of arrays not yet supported" );
   elsif class_ok( elementType, typeClass, subClass ) then  -- item type OK?
      if isExecutingCommand and not syntax_check then            -- not on synchk
         declareArrayType( id => type_id,
                    name => identifiers( newtype_id ).name,
                    first => long_integer( to_numeric( ab1 ) ),
                    last => long_integer( to_numeric( ab2 ) ),
                    ind => kind1,
                    blocklvl => blocks_top );
         identifiers( newtype_id ).value := to_unbounded_string( type_id'img );
      end if;
      identifiers( newtype_id ).kind := elementType;        -- element type
      identifiers( newtype_id ).list := true;               -- it is an array
      identifiers( newtype_id ).class := typeClass;         -- it is a type
      identifiers( newtype_id ).import := false;            -- never import
      identifiers( newtype_id ).export := false;            -- never export
   else                                                     -- otherwise
     b := deleteIdent( newtype_id );                        -- discard bad type
   end if;

end ParseArrayTypePart;

procedure ParseType is
   -- Syntax: type = "type newtype is new oldtype"
   --         type = "type arraytype is array-type-part"
   -- NOTE: enumerateds aren't overloadable (yet)
   newtype_id : identifier;
   parent_id  : identifier;
   enum_index : integer := 0;
   b : boolean;
begin

   expect( type_t );                                       -- "type"
   ParseNewIdentifier( newtype_id );                       -- typename
   expect( is_t );                                         -- is

   if Token = symbol_t and identifiers( token ).value = "(" then

      -- enumerated
      --
      -- If an error happens during the parsing, some enumerated items
      -- may be left declared.  Should use recursion for parsing the
      -- items so they can be properly "rolled back".

      identifiers( newtype_id ).kind := root_enumerated_t; -- the parent is
      identifiers( newtype_id ).class := typeClass;        -- type based on
      parent_id := newtype_id;                             -- root enumerated
      expect( symbol_t, "(" );                             -- "("
      while token /= eof_t loop                            -- name [,name]
         ParseNewIdentifier( newtype_id );                 -- enumerated item
         -- always execute declarations when syntax checking
         -- because they are needed to test types and interpret
         -- other statements
         if isExecutingCommand or syntax_check then        -- OK to do it?
            identifiers( newtype_id ).class := constClass; -- it's a type
            declare
              s : string := enum_index'img;
            begin
              -- drop leading space
              identifiers( newtype_id ).value := to_unbounded_string( s(2..s'last) );
            end;
            identifiers( newtype_id ).kind := parent_id;   -- based on parent
         else                                              -- otherwise
            b := deleteIdent( newtype_id );                -- discard item
         end if;
         enum_index := enum_index + 1;                     -- next item number
         exit when error_found or identifiers( token ).value /= ",";      -- quit when no ","
         expect( symbol_t, "," );                          -- ","
      end loop;
      expect( symbol_t, ")" );                             -- closing ")"
      if error_found or exit_block then                    -- problems?
         b := deleteIdent( parent_id );                    -- discard parent
     end if;

   elsif token = array_t then
      ParseArrayTypePart( newtype_id );
   elsif token = record_t then
      ParseRecordTypePart( newtype_id );
   else

     -- new type

     expect( new_t );                                      -- "new"
     if token = array_t then
        err( "omit " & optional_bold( "new" ) & " since array is not derived from another type" );
     end if;
     ParseIdentifier( parent_id );                         -- parent type name
     if class_ok( parent_id, typeClass, subClass ) then    -- not a type?
        if isExecutingCommand or syntax_check then         -- OK to do it?
          identifiers( newtype_id ).kind := parent_id;     -- define the type
          identifiers( newtype_id ).class := typeClass;
        else                                               -- otherwise
          b := deleteIdent( newtype_id );                  -- discard new type
        end if;
     end if;

   end if;
end ParseType;

procedure ParseSubtype is
   -- Syntax: type = "subtype newtype is oldtype"
   newtype_id : identifier;
   parent_id : identifier;
   b : boolean;
begin
   expect( subtype_t );                                    -- "subtype"
   ParseNewIdentifier( newtype_id );                       -- type name
   expect( is_t );                                         -- "is"
   ParseIdentifier( parent_id );                           -- old type
   if class_ok( parent_id, typeClass, subClass ) then      -- not a type?
      if isExecutingCommand or syntax_check then              -- OK to execute?
         identifiers( newtype_id ).kind := parent_id;         -- assign subtype
         identifiers( newtype_id ).class := subClass;         -- subtype class
      else                                                    -- otherwise
         b := deleteIdent( newtype_id );                      -- discard subtype
      end if;
   end if;
end ParseSubtype;

procedure ParseIfBlock is
-- Syntax: if-block = "if"... "elsif"..."else"..."end if"
  expr_val  : unbounded_string;
  expr_type : identifier;
  b : boolean := false;
  handled : boolean := false;
  backup_sc : boolean;
begin

  -- if expr then statements

  expect( if_t );                                          -- "if"
  if token = if_t then                                     -- this is from
     err( "redundant " & optional_bold( "if" ) );          -- GNAT
  end if;
  ParseExpression( expr_val, expr_type );                  -- expression
  if not baseTypesOk( boolean_t, expr_type ) then          -- not boolean result?
     err( "boolean expression expected" );
  else
     b := expr_val = "1";                                  -- convert to boolean
  end if;
  expect( then_t );                                        -- "then"
  if token = then_t then                                   -- this is from
     err( "redundant " & optional_bold( "then" ) );        -- GNAT
  end if;

  -- elsif expr then statements

  if b then                                                -- was true?
     ParseBlock( elsif_t, else_t );                        -- handle if block
     handled := true;                                      -- remember we did it
                                                           -- even elsifs and else line
     --syntax_check := true;
  else                                                     -- otherwise
     SkipBlock( elsif_t, else_t );                         -- skip if block
  end if;

  while token = elsif_t loop                               -- a(nother) elsif?
     if handled then                                       -- already handled?
        backup_sc := syntax_check;                         -- don't exec elsif
        syntax_check := true;
     end if;
     expect( elsif_t );                                    -- "elsif"
     if token = elsif_t then                               -- this is from
        err( "redundant " & optional_bold( "elsif" ) );    -- GNAT
     end if;
     ParseExpression( expr_val, expr_type );               -- expression
     if not baseTypesOk( boolean_t, expr_type ) then     -- not boolean result?
        err( "boolean expression expected" );
     else
        b := expr_val = "1";                               -- convert to boolean
     end if;
     if handled then                                       -- already handled?
        syntax_check := backup_sc;                         -- restore flag
     end if;                                               -- for SkipBlock
     expect( then_t );                                     -- "then"
     if token = then_t then                                -- this is from
        err( "redundant " & optional_bold( "then" ) );     -- GNAT
     end if;
     if b and not handled then                             -- true (and not previously done)
        ParseBlock( elsif_t, else_t );                     -- handle the elsif block
        handled := true;                                   -- remember we did it
        syntax_check := true;                              -- even elsifs and else line
     else                                                  -- otherwise
        SkipBlock( elsif_t, else_t );                      -- skip elsif block
     end if;
  end loop;

  -- else statements

  if token = else_t then                                   -- else part?
     if handled then                                       -- already handled?
        backup_sc := syntax_check;                         -- don't exec else
        syntax_check := true;                              -- for --trace
     end if;
     expect( else_t );                                     -- "else"
     if handled then                                       -- already handled?
        syntax_check := backup_sc;                         -- restore flag
     end if;                                               -- for SkipBlock
     if token = else_t then                                -- this is from
        err( "redundant " & optional_bold( "else" ) );     -- GNAT
     end if;
     if not handled then                                   -- nothing handled yet?
        ParseBlock;                                        -- handle else block
     else                                                  -- otherwise
        SkipBlock;                                         -- skip else block
     end if;
  end if;

  -- end if

  expect( end_t );                                         -- "end if"
  expect( if_t );

end ParseIfBlock;

procedure ParseCaseBlock is
-- Syntax: case-block = "case" ident "is" "when" const-ident ["|"...] "=>" ...
-- "when others =>" ..."end case"
  test_id : identifier;
  case_id : identifier;
  handled : boolean := false;
  b       : boolean := false;
begin

  -- case id is

  expect( case_t );                                        -- "case"
  ParseIdentifier( test_id );                              -- identifier to test
  -- we allow const because parameters are consts in Bush 1.x.
  if class_ok( test_id, constClass, otherClass ) then
     expect( is_t );                                       -- "is"
  end if;

  -- when const-id =>

  if token /= when_t then                                 -- first when missing?
     expect( when_t );                                    -- force error
  end if;
  while token = when_t loop
     expect( when_t );                                    -- "when"
     exit when error_found or token = others_t;
     -- this should be ParseConstantIdentifier
     b := false;                                          -- assume case fails
     loop
        if token = strlit_t then                          -- strlit allowed
           if baseTypesOk( identifiers( test_id ).kind, string_t ) then
              case_id := token;
              getNextToken;
           end if;
        elsif token = charlit_t then                      -- charlit allowed
           if baseTypesOk( identifiers( test_id ).kind, character_t ) then
              case_id := token;
              getNextToken;
           end if;
        elsif token = number_t then                       -- num lit allowed
           if uniTypesOk( identifiers( test_id ).kind, uni_numeric_t ) then
              case_id := token;
              getNextToken;
           end if;
        else                                             -- constant allowed
           ParseIdentifier( case_id );                         -- get the case
           if identifiers( case_id ).class /= constClass then  -- is constant?
              err( "variable not allowed as a case" );         -- error if not
           elsif baseTypesOk( identifiers( test_id ).kind,
                 identifiers( case_id ).kind ) then            -- types good?
              null;
           end if;
        end if;
        if not error_found then                         -- OK? check case
           b := b or                                    -- against test var
             identifiers( test_id ).value = identifiers( case_id ).value;
        end if;
        exit when error_found or token /= symbol_t or identifiers( token ).value /= "|";
        expect( symbol_t, "|" );                        -- expect alternate
     end loop;
     expect( symbol_t, "=>" );                             -- "=>"
     if b and not handled and not exit_block then          -- handled yet?
        ParseBlock( when_t );                              -- if not, handle
        handled := true;                                   -- and remember done
     else
        SkipBlock( when_t );                               -- else skip case
     end if;
  end loop;

  -- others part

  if token /= others_t then                                -- a little clearer
     err( "when others expected" );                        -- if pointing at
  end if;                                                  -- end case
  expect( others_t );                                      -- "others"
  expect( symbol_t, "=>" );                                -- "=>"
  if not handled and not exit_block then                   -- not handled yet?
     ParseBlock;                                           -- handle now
  else                                                     -- else just
     SkipBlock;                                            -- skip
  end if;

  -- end case

  expect( end_t );                                         -- "end case"
  expect( case_t );

end ParseCaseBlock;

procedure ParseLoopBlock is
  -- Syntax: loop-block = "loop" ... "end loop"
  exit_on_entry : boolean := exit_block;
begin

  pushBlock( newScope => false, newName => "loop loop" );  -- start new scope

  if syntax_check or exit_block then
     expect( loop_t );                                     -- "loop"
     ParseBlock;                                           -- check loop block
     goto loop_done;
  end if;

  loop
     expect( loop_t );                                     -- "loop"
     ParseBlock;                                           -- handle loop block
     exit when exit_block or error_found or token = eof_t;
     topOfBlock;                                           -- jump to top of block
  end loop;

<<loop_done>>
  pullBlock;                                               -- end of while scope
  if not syntax_check and not exit_on_entry then           -- ignore exit when checking
     if exit_block and not done then                       -- exiting and not returning?
        if trace then
           Put_trace( "exited loop" );
        end if;
        exit_block := false;                               -- we handled exit_block
     end if;
  end if;

  expect( end_t );                                         -- "end loop"
  expect( loop_t );
end ParseLoopBlock;

procedure ParseWhileBlock is
  -- Syntax: while-block = "while" bool-expr "loop" ... "end loop"
  expr_val  : unbounded_string;
  expr_type : identifier;
  b : boolean := false;
  exiting : boolean := false;
  exit_on_entry : boolean := exit_block;
begin
  pushBlock( newScope => false, newName => "while loop" ); -- start new scope

  if syntax_check or exit_block then
     expect( while_t );                                    -- "while"
     if token = while_t then                               -- this is from
        err( "redundant " & optional_bold( "while" ) );    -- GNAT
     end if;
     ParseExpression( expr_val, expr_type );               -- expression
     if not baseTypesOk( boolean_t, expr_type ) then       -- not boolean?
        err( "boolean expression expected" );
     end if;
     expect( loop_t );                                     --- "loop"
     ParseBlock;                                           -- check while block
     goto loop_done;
  end if;

  loop
     expect( while_t );                                    -- "while"
     ParseExpression( expr_val, expr_type );               -- expression
     if not baseTypesOk( boolean_t, expr_type ) then       -- not boolean?
        err( "boolean expression expected" );
        exit;
     elsif expr_val /= "1" or error_found or exit_block then -- skipping?
        expect( loop_t );                                  -- "loop"
        SkipBlock;                                         -- skip while block
        exit;                                              -- and quit
     end if;                                               -- otherwise do loop
     if trace then
        put_trace( "expression is true" );
     end if;
     expect( loop_t );                                     -- "loop"
     ParseBlock;                                           -- handle while block
     exit when exit_block or error_found or token = eof_t;
     topOfBlock;                                           -- jump to top of block
  end loop;

<<loop_done>>
  pullBlock;                                               -- end of while scope
  if not syntax_check and not exit_on_entry then           -- ignore exit when checking
     if exit_block and not done then                          -- exiting and not returning?
        if trace then
           Put_trace( "exited while loop" );
        end if;
        exit_block := false;                                  -- we handled exit_block
     end if;
  end if;

  expect( end_t );                                         -- "end loop"
  expect( loop_t );
end ParseWhileBlock;

procedure ParseForBlock is
  -- Syntax: for-block = "for" local-var "in" expr ".." expr "loop" ... "end loop"
  expr1_val  : unbounded_string;
  expr1_type : identifier;
  expr2_val  : unbounded_string;
  expr2_type : identifier;
  expr2_num  : long_float;
  b : boolean := false;
  test1 : boolean := false;
  test2 : boolean := false;
  exiting : boolean := false;
  for_var   : identifier;
  firstTime : boolean := true;
  isReverse   : boolean := false;
  exit_on_entry : boolean := exit_block;
  for_name : unbounded_string;
begin

  pushBlock( newScope => true, newName => "for loop" );  -- start new scope
  -- well, not strictly a new scope, but we'll need to do this
  -- to implement automatic declaration of the index variable

  if syntax_check or exit_block then
     -- this is complicated enough it should be in it's own nested procedure
     expect( for_t );                                   -- "for"
     for_name := identifiers( token ).name;             -- save var name
     if token = number_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "number" ) );
     elsif token = strlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "string literal" ) );
     elsif token = backlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "backquoted literal" ) );
     elsif token = charlit_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "character literal" ) );
     elsif is_keyword( token ) and token /= eof_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "keyword" ) );
     elsif token = symbol_t then
        err( optional_bold( "identifier" ) & " expected, not a " &
             optional_bold( "symbol" ) );
     elsif identifiers( token ).kind = new_t then          -- for var
        discardUnusedIdentifier( token );               -- brand new? toss it
     end if;                                            -- we'll declare it
     getNextToken;                                      -- declare after range
     expect( in_t );                                    -- "in"
     if token = reverse_t then                          -- "reverse"?
        isReverse := true;
        expect( reverse_t );
     end if;
     ParseExpression( expr1_val, expr1_type );          -- low range
     expect( symbol_t, ".." );                          -- ".."
     ParseExpression( expr2_val, expr2_type );          -- high range
     -- declare for var down here in case older var with same name
     -- used in for loop range (so that for k in k..k+1 is legit)
     declareIdent( for_var, for_name, uni_numeric_t);   -- declare for var
     if baseTypesOk( expr1_type, expr2_type ) then      -- check types
        if getUniType( expr1_type ) = uni_numeric_t then
           null;
       elsif getUniType( expr1_type ) = root_enumerated_t then
           null;
       end if;
       if not error_found then
          if isReverse then
             identifiers( for_var ).kind := expr2_type;     -- this type
          else
             identifiers( for_var ).kind := expr1_type;     -- this type
           end if;
        end if;
     end if;
     expect( loop_t );
     ParseBlock;                                           -- check for block
     goto abort_loop;
  end if;

  loop
     expect( for_t );                                      -- "for"
     if firstTime then
        if identifiers( token ).kind = new_t then          -- for var
           for_var := token;                               -- brand new? ok
        else                                               -- else declare locally
           declareIdent( for_var, identifiers( token ).name, uni_numeric_t);
        end if;
        getNextToken;
        expect( in_t );                                    -- "in"
        if token = reverse_t then                          -- "reverse"?
           isReverse := true;
           expect( reverse_t );
        end if;
        ParseExpression( expr1_val, expr1_type );          -- low range
        expect( symbol_t, ".." );                          -- ".."
        ParseExpression( expr2_val, expr2_type );          -- high range
        if verboseOpt then
           put_trace( "in " & to_string( expr1_val ) & ".." & to_string( expr2_val ) );
        end if;

        if error_found then                                -- errors?
            goto abort_loop;                               -- go no further
        end if;
        if baseTypesOk( expr1_type, expr2_type ) then      -- check types
           if getUniType( expr1_type ) = uni_numeric_t then
              null;
           elsif getUniType( expr1_type ) = root_enumerated_t then
              null;
           else
              err( "numeric or enumerated type expected" );
              -- should be err_previous but haven't exported it yet
           end if;
           if not error_found then
              if isReverse then
                 identifiers( for_var ).value := expr2_val;     -- for var is
                 identifiers( for_var ).kind := expr2_type;     -- this type
                 if isExecutingCommand then
                    expr2_num := to_numeric( expr1_val );
                 end if;
              else
                 identifiers( for_var ).value := expr1_val;     -- for var is
                 identifiers( for_var ).kind := expr1_type;     -- this type
                 if isExecutingCommand then
                    expr2_num := to_numeric( expr2_val );
                 end if;
              end if;
           end if;
        end if;
        expect( loop_t );                                  -- "loop"
        firstTime := false;                                -- don't do this again
     else
        -- don't interpret for line after first time
-- is this necessary any more?
        while token /= loop_t loop                         -- skip to
           getNextToken;                                 -- "loop"
        end loop;
        expect( loop_t );
        if isReverse then
           if isExecutingCommand then
              identifiers( for_var ).value := to_unbounded_string(
                  long_float( to_numeric( identifiers( for_var ).value ) - 1.0 ) );
           end if;
        else
           if isExecutingCommand then
              identifiers( for_var ).value := to_unbounded_string(
                  long_float( to_numeric( identifiers( for_var ).value ) + 1.0 ) );
           end if;
        end if;
     end if;
     if not isExecutingCommand then -- includes errors or exiting
        skipBlock;
        exit;
     elsif isReverse then
        if to_numeric( identifiers( for_var ).value ) < expr2_num then
           skipBlock;
           exit;
        end if;
     elsif to_numeric( identifiers( for_var ).value ) > expr2_num then
         skipBlock;
         exit;
     end if;
     if trace then
        put_trace(
            to_string( identifiers( for_var ).name ) & " := '" &
            to_string( identifiers( for_var ).value ) & "'" );
     end if;
     ParseBlock;                                           -- handle for block
     exit when exit_block or error_found or token = eof_t;
     topOfBlock;                                           -- jump to top of block
  end loop;

<<abort_loop>>
  pullBlock;                                               -- end of while scope
  if not syntax_check and not exit_on_entry then           -- ignore exit when checking
     if exit_block and not done then                          -- exiting and not returning?
        if trace then
           Put_trace( "exited for loop" );
        end if;
        exit_block := false;                                  -- we handled exit_block
     end if;
  end if;

  expect( end_t );                                         -- "end loop"
  expect( loop_t );

end ParseForBlock;

procedure ParseDelay is
  -- Syntax: delay expression
  -- Source: Ada built-in
  expr_val  : unbounded_string;
  expr_type : identifier;
begin
  expect( delay_t );
  ParseExpression( expr_val, expr_type );
  if baseTypesOk( expr_type, duration_t ) then
     if isExecutingCommand then
        begin
          delay duration( to_numeric( expr_val ) );
        exception when others =>
          err( "exception raised" );
        end;
        if trace then
           put_trace( "duration := " & to_string( expr_val ) );
        end if;
     end if;
  end if;
end ParseDelay;

procedure ParseTypeset is
  -- Syntax: typeset identifier is type
  -- Source: BUSH built-in
  id     : identifier;
  typeid : identifier := eof_t;
  b      : boolean;
begin
   expect( typeset_t );
   if onlyAda95 then
      discardUnusedIdentifier( token );
      err( "typeset is not allowed with " & optional_bold( "pragma ada_95" ) );
      return;
   elsif inputMode /= interactive and inputMode /= breakout then
      discardUnusedIdentifier( token );
      err( "typeset only allowed in an interactive session" );
      return;
   end if;
   if identifiers( token ).kind = new_t then
      ParseNewIdentifier( id );
   else
      ParseIdentifier( id );
   end if;
   if token = is_t then
      expect( is_t );
      ParseIdentifier( typeid );
   end if;
   if isExecutingCommand then
      if typeid = eof_t then
         identifiers( id ).kind := universal_t;
      elsif identifiers( id ).list then
         err( "typeset with array types not yet implemented" );
      elsif identifiers( typeid ).list then
         err( "typeset with array types not yet implemented" );
      else
         identifiers( id ).kind := typeid;
      end if;
   else
      b := deleteIdent( id );
   end if;
end ParseTypeset;


-----------------------------------------------------------------------------
--  PARSE SHELL WORD
--
-- Parse and expand a shell word argument.  Return a shellWordList containing
-- the original pattern, the expanded words and their types.  If the first is
-- true, the word should be the first word.  If there is already shell words
-- in the list, any new words will be appended to the list.  The caller is
-- responsible for clearing (deallocating) the list.
--   Expansion is the process of performing substitutions on a shell word.
--
-- Bourne shell expansions include:
--   TYPE                  PATTERN        EX. WORDS        STATUS
--   Brace expansion       a{.txt,.dat}   a.txt a.dat      not implemented
--   Tilde expansion       ~/a.txt        /home/ken/a.txt  OK
--   Variable expansion    $HOME/a.txt    /home/ken/a.txt  no special $
--   Command substituion   `echo a.txt`   a.txt            no $(...)
--   Arithmetic expansion  -              -                not implemented
--   Word splitting        a\ word        "a word"         OK
--   Pathname expansion    *.txt          a.txt b.txt      OK
--
-- Since BUSH has to interpret the shell words as part of the byte code
-- compilation, word splitting before pathname expansion.  This means that
-- certain rare expansions will have different results in BUSH than in a
-- standard Bourne shell.  (Some might call this an improvement over the
-- standard.)  Otherwise, BUSH conforms to the Bourne shell standard.
--
-- The wordType is used to differentiate between words like "|" (a string)
-- and | (the pipe operator) which look the same once quotes are removed.
-----------------------------------------------------------------------------

procedure ParseShellWord( wordList : in out shellWordList.List; First : boolean := false ) is

-- these should be global
semicolon_string : constant unbounded_string := to_unbounded_string( ";" );
--   semi-colon, as an unbounded string
                                                                                
verticalbar_string : constant unbounded_string := to_unbounded_string( "|" );
--   vertical bar, as an unbounded string
                                                                                
ampersand_string : constant unbounded_string := to_unbounded_string( "&" );
--   ampersand, as an unbounded string
                                                                                
redirectIn_string : constant unbounded_string := to_unbounded_string( "<" );
--   less than, as an unbounded string
                                                                                
redirectOut_string : constant unbounded_string := to_unbounded_string( ">" );
--   greater than, as an unbounded string
                                                                                
redirectAppend_string : constant unbounded_string := to_unbounded_string( ">>" );
--   double greater than, as an unbounded string
                                                                                
redirectErrOut_string : constant unbounded_string := to_unbounded_string( "2>" );
--   '2' + greater than, as an unbounded string
                                                                                
redirectErrAppend_string : constant unbounded_string := to_unbounded_string( "2>>" );
--   '2' + double greater than, as an unbounded string
                                                                                
redirectErr2Out_string : constant unbounded_string := to_unbounded_string( "2>&1" );
--   '2' + greater than + ampersand and '1', as an unbounded string
                                                                                
itself_string : constant unbounded_string := to_unbounded_string( "@" );
--   itself, as an unbounded string

  ch          : character;
  inSQuote    : boolean := false;                      -- in single quoted part
  inDQuote    : boolean := false;                      -- in double quoted part
  inBQuote    : boolean := false;                      -- in double quoted part
  inBackslash : boolean := false;                      -- in backquoted part
  inDollar    : boolean := false;                      -- $ expansion
  expansionVar: unbounded_string;                      -- the $ name
  escapeGlobs : boolean := false;                      -- escaping glob chars
  ignoreTerminatingWhitespace : boolean := false;                 -- SQL word has whitespace in it (do not use whitespace as a word terminator)
  expandInSingleQuotes : boolean := false;  -- SQL words allow $ expansion for single quotes (for PostgreSQL)
  stripQuoteMarks : boolean := true; -- SQL words require quotes words left in the word
  startOfBQuote : integer;

  addExpansionSQuote : boolean := false;               -- SQL, add ' after exp
  addExpansionDQuote : boolean := false;               -- SQL, add " after exp
  temp_id     : identifier;                            -- for ~ processing
  shell_word  : unbounded_string;

  word        : unbounded_string;
  wordLen     : integer := length( word );
  pattern     : unbounded_string;
  wordType    : aShellWordType;

  procedure dollarExpansion is
     -- perform a dollar expansion by appending a variable's value to the
     -- shell word.
-- NOTE: what about $?, $#, $1, etc?  These need to be handed specially here?
-- NOTE: special $ expansion, including ${...} should be handled here
     id      : identifier;
     subword : unbounded_string;
     ch      : character;
  begin
    -- put_line( "dollarExpansion for var """ & expansionVar & """" ); -- DEBUG
    -- Handle Special Substitutions ($#, $? $$, $0...$9 )
    if expansionVar = "#" then
       subword := to_unbounded_string( integer'image( Argument_Count-optionOffset) );
       delete( subword, 1, 1 );
    elsif expansionVar = "?" then
       subword := to_unbounded_string( last_status'img );
       delete( subword, 1, 1 );
    elsif expansionVar = "$" then
       subword := to_unbounded_string( aPID'image( getpid ) );
       delete( subword, 1, 1 );
    elsif expansionVar = "0" then
       subword := to_unbounded_string( Ada.Command_Line.Command_Name );
    elsif length( expansionVar ) = 1 and (expansionVar >= "1" and expansionVar <= "9" ) then
       begin
          subword := to_unbounded_string(
                 Argument(
                   integer'value(
                     to_string( " " & expansionVar ) )+optionOffset ) );
       exception when program_error =>
          err( "program_error exception raised" );
       when others =>
          err( "no such argument" );
       end;
    else
       -- Regular variable substitution
       findIdent( expansionVar, id );
       if id = eof_t then
          err( optional_bold( to_string( expansionVar ) ) & " not declared" );
       else
          subword := identifiers( id ).value;              -- word to substit.
          if getUniType( id ) = uni_numeric_t then         -- a number?
             if length( subword ) > 0 then                 -- something there?
                if element( subword, 1 ) = ' ' then        -- leading space
                   delete( subword, 1, 1 );                -- we don't want it
                end if;
             end if;
          end if;
       end if;
    end if;
    -- escapeGlobs affects the variable substitution
    for i in 1..length( subword ) loop                  -- each letter
        ch := element( subword, i );                    -- get it
        if escapeGlobs and not inBackslash then         -- esc glob chars?
           case ch is                                   -- is a glob char?
           when '*' => pattern := pattern & "\";        -- escape *
           when '[' => pattern := pattern & "\";        -- escape [
           when '\' => pattern := pattern & "\";        -- escape \
           when '?' => pattern := pattern & "\";        -- escape *
           when others => null;                         -- others? no esc
           end case;
        end if;
        pattern := pattern & ch;                        -- add the letter
        word := word & ch;                              -- add the letter
    end loop;
    inDollar := false;
  -- SQL words require the quote marks to be left intact in the word.
  -- Unfortunately, this has to be checked after the quote character has
  -- been processed.  This checks for the flag variables to attach a quote
  -- mark retroactively.
    if addExpansionSQuote then
        word := word & "'";
	addExpansionSQuote := false;
    end if;
    if addExpansionDQuote then
        word := word & ASCII.Quotation;
	addExpansionDQuote := false;
    end if;
  end dollarExpansion;
  
  -- parseShellWord: pathnameExpansion
  --
  -- Perform shell pathname expansion by using the shell word as a glob
  -- pattern and searching the current directory.  Return a list of shell
  -- words created by the expansion.
  --
  -- Note: file name length is limited to 256 characters.
    
  procedure pathnameExpansion( word, pattern : unbounded_string; list : in out shellWordList.List ) is
    globCriteria : regexp;
    currentDir   : Dir_Type;
    fileName     : string(1..256);
    fileNameLen  : natural;
    found        : boolean := false;
    noPWD        : boolean := false;
    dirpath      : string := to_string( dirname( word ) );
    globexpr     : string := to_string( basename( pattern ) );
    noDir        : boolean;
    isOpen       : boolean := false;
  begin
    -- put_line( "pathnameExpansion for original pattern """ & pattern & """" ); -- DEBUG
    -- put_line( "pathnameExpansion for expanded word """ & word & """" ); -- DEBUG
    -- word is an empty string? it still counts: param is a null string
    if length( pattern ) = 0 or length( word ) = 0 then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, null_unbounded_string ) );
       return;
    end if;
    -- otherwise, prepare to glob the current directory
    noDir := globexpr = pattern;
    globCriteria := Compile( globexpr, Glob => true, Case_Sensitive => true );
    begin
      open( currentDir, dirpath );
      isOpen := true;
    exception when others =>
      noPWD := true;
    end;
    -- is the current directory invalid? then param is just the word
    if noPWD then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, word ) );
       return;
    end if;
    -- Linux/UNIX: skip "." and ".." directory entries
    read( currentDir, fileName, fileNameLen );
    read( currentDir, fileName, fileNameLen );
    -- search the directory, adding files that match the glob pattern
    loop
      read( currentDir, fileName, fileNameLen );
      exit when fileNameLen = 0;
      if Match( fileName(1..fileNameLen ) , globCriteria ) then
         if noDir then
	    shellWordList.Queue( list, aShellWord'(
	       normalWord,
	       pattern,
	       to_unbounded_string( fileName( 1..fileNameLen ) ) ) );
         else
	    shellWordList.Queue( list, aShellWord'(
	       normalWord,
	       pattern,
	       to_unbounded_string( dirpath & directory_delimiter & fileName( 1..fileNameLen ) ) ) );
         end if;
         found := true;
      end if;
    end loop;
    -- there are no matches? word still counts: the param is just the word
    if not found then
       shellWordList.Queue( list, aShellWord'( normalWord, pattern, word ) );
    end if;
    if isOpen then
       close( currentDir );    
    end if;
  exception when ERROR_IN_REGEXP =>
    err( "error in globbing expression """ & globExpr & """" );
    if isOpen then
       close( currentDir );    
    end if;
  when DIRECTORY_ERROR =>
    err( "directory error on directory " & dirPath );
  end pathnameExpansion;
 
begin

  word := null_unbounded_string;
  pattern := null_unbounded_string;
  wordType := normalWord;

  -- Get the next unexpanded word.  A SQL command is a special case: never
  -- expand it.  We don't want the * in "select *" to be replaced with a list
  -- of files.

  -- ignoreTerminatingWhitespace is a workaround and should be redone.  We
  -- need one word but expand the items in the word (for SQL).
  
  if token = sql_word_t then
     shell_word := identifiers( token ).value;
     ignoreTerminatingWhitespace := true;                -- word contains space
     expandInSingleQuotes := true;
     stripQuoteMarks := false;
     getNextToken;
  else
     -- Otherwise, get a non-SQL shell word
     ParseBasicShellWord( shell_word );
  end if;

  -- Null string shell word?  Then nothing to do.

  if length( shell_word ) = 0 then
     word := null_unbounded_string;
     pattern := null_unbounded_string;
     wordType := normalWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;
  end if;

  -- Special Cases
  --
  -- The special shell words are always unescaped and never expand.  We handle
  -- them as special cases before beginning the expansion process.

  ch := Element( shell_word, 1 );                      -- next character

  if ch = ';' then                                     -- semicolon?
     word := semicolon_string;                         -- type
     pattern := semicolon_string;
     wordType := semicolonWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;

  elsif ch = '|' then                                  -- vertical bar?
     word := verticalbar_string;
     pattern := verticalbar_string;
     wordType := pipeWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;

  elsif ch = '&' then                                  -- ampersand?
     word := ampersand_string;                         -- type
     pattern := ampersand_string;
     wordType := ampersandWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;

  elsif ch = '<' then                                  -- less than?
     word := redirectIn_string;                        -- type
     pattern := redirectIn_string;
     wordType := redirectInWord;
     shellWordList.Queue( wordList, aShellWord'( wordtype, pattern, word ) );
     return;

  elsif ch = '>' then                                  -- greater than?

     if wordLen > 1 and then Element(shell_word, 2 ) = '>' then -- double greater than?
        word := redirectAppend_string;                 -- type
        pattern := redirectAppend_string;
        wordType := redirectAppendWord;
        shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
        return;
     end if;
     word := redirectOut_string;                       -- it's redirectOut
     pattern := redirectOut_string;
     wordType := redirectOutWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;

  elsif ch = '2' and then wordLen > 1 and then Element(shell_word, 2 ) = '>' then -- 2+greater than?
     if wordLen > 2 and then Element( shell_word, 3  ) = '&' then            -- fold error into out?
        if wordLen > 3 and then Element( shell_word, 4 ) = '1' then
           word := redirectErr2Out_string;              -- type
           pattern := redirectErr2Out_string;
           wordType := redirectErr2OutWord;
           shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
           return;
        end if;
     elsif wordLen > 2 and then Element( shell_word, 3 ) = '>' then -- double greater than?
        word := redirectErrAppend_string;               -- it's redirectErrApp
        pattern := redirectErrAppend_string;
        wordType := redirectErrAppendWord;
        shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
        return;
     end if;
     word := redirectErrOut_string;                     -- it's redirectErrOut
     pattern := redirectErrOut_string;
     wordType := redirectErrOutWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;

  elsif ch = '@' then                                   -- itself?
     word := itself_string;                             -- it's an itself type
     pattern := itself_string;
     wordType := itselfWord;
     shellWordList.Queue( wordList, aShellWord'( wordType, pattern, word ) );
     return;

  end if;

  -- There are times when we don't want to expand the word.  In the case of
  -- a syntax check, return the word as-is as a place holder (not sure if
  -- it's necessary but "> $path" becomes ">" with no path otherwise...at
  -- least, it's easier for the programmer to debug.

  if error_found then                                 -- error:
     return;                                          -- no expansions
  elsif syntax_check then                             -- chk?
     shellWordList.Queue( wordList, aShellWord'( normalWord, pattern, shell_word ) );
     return;                                          -- just the word
  end if;                                             -- as a place holder

  ---------------------------------------------------------------------------
  -- We have a word.  Perform the expansion: process quotes and other escape
  -- characters, possibly creating multiple words from one original pattern.
  ---------------------------------------------------------------------------

  -- Expand any quotes quotes and handle shell variable substitutions

  for i in 1..length( shell_word ) loop
    ch := Element( shell_word, i );                          -- next character

       -- Double Quote?  If not escaped by a backslash or single quote,
       -- we're in a new double quote escape.  If we were in a dollar expansion,
       -- perform the expansion.

    if ch = '"' and not inSQuote and not inBackslash then    -- unescaped "?
       inDQuote := not inDQuote;                             -- toggle " flag
       if inDollar then                                      -- was doing $?
          dollarExpansion;                                   -- complete it
       end if;
       if not stripQuoteMarks then                           -- SQL word?
	  if inDollar then                                   -- in an exp?
	     addExpansionDQuote := true;                     -- add after exp
          else                                               -- else
             word := word & """";                            -- add quote now
	  end if;
       end if;
       escapeGlobs := inDQuote;                              -- inside? do esc

       -- Single Quote?  If not escaped by a backslash or double quote,
       -- we're in a new single quote escape.  If we were in a dollar expansion,
       -- perform the expansion.

    elsif ch = ''' and not inDQuote and not inBackslash then -- unescaped '?
       inSQuote := not inSQuote;                             -- toggle ' flag
       if inDollar then                                      -- was doing $?
          dollarExpansion;                                   -- complete it
       end if;
       if not stripQuoteMarks then                           -- SQL word?
	  if inDollar then                                   -- in an exp?
	     addExpansionSQuote := true;                     -- add after exp
	  else                                               -- else
	     word := word & "'";                             -- add quote now
	  end if;
       end if;
       escapeGlobs := inSQuote;                              -- inside? do esc

       -- Back Quote?  If not escaped by a backslash or single quote,
       -- we're in a new back quote escape.  If we were in a dollar expansion,
       -- perform the expansion before executing the back quote.

    elsif ch = '`' and not inSQuote and not inBackslash then -- unescaped `?
       inBQuote := not inBQuote;                             -- toggle ` flag
       if inBQuote and inDollar then                         -- doing $ ere `?
          dollarExpansion;                                   -- complete it
       end if;
       if inBQuote then                                      -- starting?
          startOfBQuote := length( word );                   -- offset to start
       else                                                  -- ending?
          if inDollar then                                   -- in a $?
             dollarExpansion;                                -- finish it
          end if;
--put_line( "PSW: " & word );
--put_line( "PSW: " & startOfBQuote'img );
--put_line( "PSW: " & length( word )'img );
--put_line( "PSW: " & slice( word, startOfBQuote+1, length( word ) ) );
         declare
            -- to run this backquoted shell word, we need to save the current
            -- script, compile the command into byte code, and run the commands
            -- while capturing the output.  Substitute the results into the
            -- shell word and restore the original script.
            tempStr : unbounded_string := to_unbounded_string( slice( word, startOfBQuote+1, length( word ) ) );
            result : unbounded_string;
         begin
            delete( word, startOfBQuote+1, length( tempStr ) );
            CompileRunAndCaptureOutput( tempStr, result );
            word := word & result;
         end;
       end if;
       escapeGlobs := inBQuote;                            -- inside? do esc

       -- Backslash?  If not escaped by another backslash or single quote,
       -- we're in a new backslash escape.  If we were in a dollar expansion,
       -- perform the expansion.  Keep the backslashes for pathname expansion
       -- but not for SQL words.

    elsif ch = '\' and not inSQuote and not inBackslash then -- unescaped \?
       inBackslash := true;                                -- \ escape
       if inDollar then                                    -- in a $?
          dollarExpansion;                                 -- complete it
       end if;

       pattern := pattern & "\";                           -- an escaping \

       -- Dollar sign?  Then begin collecting the letters to the substitution
       -- variable.

    elsif ch = '$' and not (inSQuote and not expandInSingleQuotes) and not inBackslash then
       if inDollar then                                    -- in a $?
          if length( expansionVar ) = 0 then               -- $$ is special
             expansionVar := expansionVar & ch;            -- var is $
             dollarExpansion;                              -- expand it
          else                                             -- otherwise
             dollarExpansion;                              -- complete it
             inDollar := true;                             -- start new one
          end if;
       else                                                -- not in one?
          inDollar := true;                                -- start new one
       end if;
       expansionVar := null_unbounded_string;
    else

       -- End of quote handling...now we have a character, handle it

       -- Terminating characters (whitespace or semi-colon)
       exit when (ch = ' ' or ch = ASCII.HT or ch = ';' or ch = '|' )
          and not inDQuote and not inSQuote and not inBQuote and not inBackslash and not ignoreTerminatingWhitespace;
       -- Looking at a $ expansion?  Then collect the letters of the variable
       -- to substitute but don't add them to the shell word.  Apply dollar
       -- expansions to both word and pattern.
       if inDollar then                                    -- in a $?
          expansionVar := expansionVar & ch;               -- collect $ name
       else                                                -- not in $?
          -- When escaping characters that affect globbing, this is only done
          -- for the pattern to be used for globbing.  Do not escape the
          -- characters in the word...this will be the fallback word used if
          -- globbing fails to match any files.
          -- backslash => user already escaped it
          if escapeGlobs and not inBackslash then          -- esc glob chars?
             case ch is                                    -- is a glob char?
             when '*' => pattern := pattern & "\";         -- escape *
             when '[' => pattern := pattern & "\";         -- escape [
             when '\' => pattern := pattern & "\";         -- escape \
             when '?' => pattern := pattern & "\";         -- escape *
             when others => null;                          -- others? no esc
             end case;
          end if;
          pattern := pattern & ch;                         -- add the char
          word := word & ch;                               -- original word
          if inBackslash then                              -- \ escaping?
             inBackslash := false;                         -- not anymore
          end if;
       end if;
    end if;
  end loop;                                                -- expansions done
  if inDollar then                                         -- last $ not done ?
     dollarExpansion;                                      -- finish it
  end if;

  -- These should never occur because of the tokenizing process, but
  -- to be safe there should be no open quotes.
                                                                                
  if inSQuote then
     err( "Internal error: missing single quote mark" );
  elsif inDQuote then
     err( "Internal error: missing double quote mark" );
  end if;
 
  -- process special characters

  for i in 1..length( word ) loop

      if Element( word, i ) = '~' then                      -- leading tilda?
         findIdent( to_unbounded_string( "HOME" ), temp_id ); -- find HOME var
         pattern := identifiers( temp_id ).value;          -- replace w/HOME
      end if;

  end loop;
 
  -- Don't expand pathname during syntax check
 
  if isExecutingCommand then
     pathnameExpansion( word, pattern, wordList );

     if trace then
        declare
          theWord : aShellWord;
        begin
          if ignoreTerminatingWhitespace then
             put_trace( "SQL word '" & to_string( toEscaped( pattern ) ) &
                "' expands to:" );
          else
             put_trace( "shell word '" & to_string( toEscaped( pattern ) ) &
                "' expands to:" );
          end if;
          for i in 1..shellWordList.length( wordList ) loop
              shellWordList.Find( wordList, i, theWord );
              put_trace( to_string( toEscaped( theWord.word ) ) );
          end loop;
        end;
     end if;
  end if;

end ParseShellWord;


-----------------------------------------------------------------------------
--  PARSE ONE SHELL WORD
--
-- Parse and expand one shell word arguments.  Return the resulting pattern,
-- the expanded word, and the type of word.  First should be true if the word
-- can be a command.  An error occurs if the word can expand into more than
-- one word.
-----------------------------------------------------------------------------

procedure ParseOneShellWord( wordType : out aShellWordType;
   pattern, word : in out unbounded_string; First : boolean := false ) is
   wordList : shellWordList.List;
   theWord  : aShellWord;
begin
   ParseShellWord( wordList, First );
   if shellWordList.Length( wordList ) > 1 then
      err( "one word expected but there were multiple matches" );
   else
      shellWordList.Find( wordList, 1, theWord );
      wordType := theWord.wordType;
      pattern  := theWord.pattern;
      word     := theWord.word;
   end if;
   shellWordList.Clear( wordList );
end ParseOneShellWord;


-----------------------------------------------------------------------------
--  PARSE SHELL WORDS
--
-- Parse and expand zero or more shell word arguments.  Return the results
-- as a shellWordList.  First should be true if the first word is a command.
--
-- A list of shell words ends with either a semi-colon (the end of a general
-- statement) or when a pipe or @ is read in as a parameter.  Do not include
-- a semi-colon in the parameters.
-----------------------------------------------------------------------------

procedure ParseShellWords( wordList : in out shellWordList.List; First : boolean := false ) is
   theWord  : aShellWord;
   theFirst : boolean := First;
begin
   loop
     exit when token = symbol_t and identifiers( token ).value = ";";
     ParseShellWord( wordList, theFirst );
     theFirst := false;
     shellWordList.Find( wordList, shellWordList.Length( wordList ), theWord );
     exit when theWord.wordType = pipeWord;       -- pipe always ends a command
     exit when theWord.wordType = itselfWord;     -- itself always ends a command
     exit when error_found;
   end loop;
end ParseShellWords;


procedure ParseVm is
-- vm regtype, regnum
  regtype_val  : unbounded_string;
  regtype_kind : identifier;
  regnum_val   : unbounded_string;
  regnum_kind  : identifier;
begin
  ParseExpression( regtype_val, regtype_kind );
  if baseTypesOK( regtype_kind, string_t ) then
     expect( symbol_t, "," );
     ParseExpression( regnum_val, regnum_kind );
     if baseTypesOK( regnum_kind, integer_t ) then
        null;
     end if;
  end if;
  builtins.vm( regtype_val, regnum_val );
end ParseVm;

procedure ParseProcedureBlock;
procedure ParseFunctionBlock;

procedure ParseDeclarations is
  -- Syntax: declaration = "new-ident decl-part"
  var_id : identifier;
  save_syntax_check : boolean;
begin
  while token /= begin_t and token /= end_t and token /= eof_t loop
     if token = pragma_t then
        ParsePragma;
        expectSemicolon;
     elsif token = type_t then
        ParseType;
        expectSemicolon;
     elsif token = subtype_t then
        ParseSubtype;
        expectSemicolon;
     elsif Token = procedure_t then
        -- When parsing a procedure declaration, we never want to run it.
        save_syntax_check := syntax_check;
        syntax_check := true;
        ParseProcedureBlock;
        syntax_check := save_syntax_check;
     elsif Token = function_t then
        -- When parsing a function declaration, we never want to run it.
        save_syntax_check := syntax_check;
        syntax_check := true;
        ParseFunctionBlock;
        syntax_check := save_syntax_check;
     else
        ParseNewIdentifier( var_id );
        ParseDeclarationPart( var_id, anon_arrays => true ); -- var id may change...
        expectSemicolon;
     end if;
  end loop;
end ParseDeclarations;

procedure SkipBlock( termid1, termid2 : identifier := keyword_t ) is
  old_error : boolean;
begin
  if token = end_t or token = eof_t or token = termid1 or token = termid2 then
     err( "missing statement or command" );
  end if;
  if syntax_check then               -- if we're checking syntax
     ParseBlock( termid1, termid2 ); -- must process the block to look
     return;                         -- for syntax errors
  end if;
  --old_error := error_found;          -- save error code
  --error_found := true;               -- skip by setting error flag
  old_error := syntax_check;
  syntax_check := true;
  -- if an error happens in the block, we were skipping it anyway...
  while token /= end_t and token /= eof_t and token /= termid1 and token /= termid2 loop
      ParseGeneralStatement;         -- step through context
  end loop;
  --error_found := old_error;          -- ignore any error while skipping
  syntax_check := old_error;
end SkipBlock;

procedure ParseBlock( termid1, termid2 : identifier := keyword_t ) is
  -- Syntax: block = "general-stmt [general-stmt...] termid1 | termid2"
begin
  if token = end_t or token = eof_t or token = termid1 or token = termid2 then
     err( "missing statement or command" );
  end if;
  while token /= end_t and token /= eof_t and token /= termid1 and token /= termid2 loop
     ParseGeneralStatement;
  end loop;
end ParseBlock;

procedure ParseDeclareBlock is
begin
  pushBlock( newScope => true, newName => "declare block" );
  expect( declare_t );
  ParseDeclarations;
  expect( begin_t );
  ParseBlock;
  expect( end_t );
  pullBlock;
end ParseDeclareBlock;

procedure ParseBeginBlock is
begin
  pushBlock( newScope => true, newName => "begin block" );
  expect( begin_t );
  ParseBlock;
  expect( end_t );
  pullBlock;
end ParseBeginBlock;

procedure ParseFormalParameters( proc_id : identifier; param_no : in out integer ) is
-- Syntax: (field = declaration [; declaration ... ] )
-- Fields are implemented using records
   formal_param_id : identifier;
   b : boolean;
   paramName : unbounded_string;
   type_token    : identifier;
begin
  param_no := param_no + 1;
  ParseNewIdentifier( formal_param_id );

  expect( symbol_t, ":" );

  -- Check the parameter mode

  if token = out_t then
     err( "out parameters not yet supported" );
  elsif token = in_t then
     expect( in_t );
     if token = out_t then
        err( "in out parameters not yet supported" );
     end if;
  elsif token = access_t then
     err( "access parameters not yet supported" );
  end if;

  -- Check for anonymous array

  if token = array_t then
     err( "anonymous array parameters not yet supported" );
  end if;

  -- The name of the type

  ParseIdentifier( type_token );

  -- Check type

  if identifiers( getBaseType( type_token ) ).list then
     err( "array parameters not yet supported" );
  elsif identifiers( getBaseType( type_token ) ).kind = root_record_t then
     err( "records not yet supported" );
  elsif getBaseType( type_token ) = command_t then
     err( "commands not yet supported" );
  end if;

  -- Check for default value

  if token = symbol_t and identifiers( token ).value = ":=" then
     err( "default values are not supported" );
  end if;

  -- Create the parameter

  updateFormalParameter( formal_param_id, type_token, proc_id, param_no );

  -- Check for further parameters

  if not error_found and token /= eof_t and not (token = symbol_t and identifiers( token ).value = ")" ) then
     expectSemicolon;
     ParseFormalParameters( proc_id, param_no );
     -- the symbol table will overflow before field_no does
  end if;

  -- Blow away on error

  if error_found then
     b := deleteIdent( formal_param_id );
  end if;
end ParseFormalParameters;

procedure ParseFunctionReturnPart( func_id : identifier ) is
-- Syntax: (field = declaration [; declaration ... ] )
-- Fields are implemented using records
   formal_param_id : identifier;
   b : boolean;
   paramName : unbounded_string;
   type_token    : identifier;
begin
  expect( return_t );

  -- The name of the type

  ParseIdentifier( type_token );
  identifiers( func_id ).kind := type_token;

  -- Check type

  if identifiers( getBaseType( type_token ) ).list then
     err( "array parameters not yet supported" );
  elsif identifiers( getBaseType( type_token ) ).kind = root_record_t then
     err( "records not yet supported" );
  elsif getBaseType( type_token ) = command_t then
     err( "commands not yet supported" );
  end if;

  -- Create the parameter

  declareIdent( formal_param_id, to_unbounded_string( "return value" ), type_token, otherClass );
  updateFormalParameter( formal_param_id, type_token, func_id, 0 );

  -- Blow away on error

  if error_found then
     b := deleteIdent( formal_param_id );
  end if;
end ParseFunctionReturnPart;

procedure DeclareActualParameters( proc_id : identifier ) is
  actual_param_t : identifier;
  param_no : natural;
begin
  if not error_found then
     -- unlike arrays, user-defined functions and procedures do not have
     -- a total number of parameters stored in their value field

     -- functions have an extra, hidden actual parameter for the function
     -- result (parameter zero).

     if identifiers( proc_id ).class = userFuncClass then
         declareReturnResult(
            actual_param_t,
            proc_id );
     end if;

     param_no := 1;
     loop 
         declareActualParameter(
            actual_param_t,
            proc_id,
            param_no,
            null_unbounded_string );
     exit when actual_param_t = eof_t;
         param_no := param_no + 1;
     end loop;
  end if;
end DeclareActualParameters;


procedure ParseSeparateProcHeader( proc_id : identifier; procStart : out natural ) is
  -- Syntax: separate( parent ); procedure p [(param1...)] is
  -- Note: forward declaration handling not yet written so minimal parameter
  -- checking in the header.
  separate_proc_id : identifier;
  parent_id        : identifier;
  b : boolean;
  pu : unbounded_string;
  i : integer;
  ch : character;
begin
   getFullParentUnitName( pu );
   -- separate
   expectSemicolon;
   expect( separate_t );
   expect( symbol_t, "(");
   ParseIdentifier( parent_id );
   -- NOTE: the identifier token returned has the prefix stripped!  This needs
   -- to be fixed so I cannot check to see if it was full path before stripping.
   i := length( pu );
   while i > 0 loop
     ch := element( pu, i );
     if ch = '.' then
        delete( pu, 1, i );
        exit;
     end if;
     i := i - 1;
   end loop;
   if identifiers( parent_id ).class /= userProcClass and identifiers( parent_id ).class /= userFuncClass and identifiers( parent_id ).class /= mainProgramClass then
         err( "parent unit should be a subprogram" );
   elsif identifiers( parent_id ).name /= pu then
         err( "expected parent unit " & optional_bold( to_string( pu ) ) );
   end if;
   expect( symbol_t, ")");
   expectSemicolon;
   -- separate's procedure header
   procStart := firstPos;
   expect( procedure_t );
   -- could do ParseIdentifier since it should exist but want a more meaningful
   -- message error for a mismatch
   ParseProcedureIdentifier( separate_proc_id );
   if identifiers( separate_proc_id ).value = identifiers( proc_id ).value then
      -- names match?  OK, discard.  proc is stored under original ident
      b := deleteIdent( separate_proc_id );
   else
      err( optional_bold( to_string( identifiers( separate_proc_id ).name ) ) & " is different from parent file's " & optional_bold( to_string( identifiers( proc_id  ).name ) ) );
   end if;
   -- check for forward declarations not yet written so minimal checking here
   -- flush this out if i have time to walk the identifiers list if available
   if token = symbol_t and identifiers( token ).value = "(" then
      expect( symbol_t, "(" );
      while token /= symbol_t and identifiers( token ).value /= ")" and token /= eof_t loop
         getNextToken;
      end loop;
      expect( symbol_t, ")" );
   end if;
   expect( is_t );
end ParseSeparateProcHeader;


procedure ParseProcedureBlock is
  -- Syntax: procedure p [(param1...)] OR procedure p [(param1...)] is block
  -- end p;
  -- Handle procedure declarations, including forward declarations.
  -- Note: DoUserDefinedProcedure executes a user-defined procedure created by
  -- this routine.
  proc_id   : identifier;
  procStart : natural;
  procEnd   : natural;
  no_params   : integer;
begin
  procStart := firstPos;
  expect( procedure_t );
  ParseProcedureIdentifier( proc_id );
  -- A forward declaration?
  if token /= is_t and not (token = symbol_t and identifiers( token ).value = "(" ) then
     -- the following is only true for a forward declaration
     -- (otherwise PPI will return otherClass)
     if identifiers( proc_id ).class = userProcClass then
        err( "already forward declared " & optional_bold( to_string( identifiers( proc_id ).name ) ) );
     end if;
     identifiers( proc_id ).class := userProcClass;
     identifiers( proc_id ).kind := procedure_t;
     -- otherwise, nothing special for a forward declaration
  else
     identifiers( proc_id ).class := userProcClass;
     identifiers( proc_id ).kind := procedure_t;
     if token = symbol_t and identifiers( token ).value = "(" then
        expect( symbol_t, "(" );
        no_params := 0;
        ParseFormalParameters( proc_id, no_params );
        expect( symbol_t, ")" );
        --identifiers( proc_id ).value := to_unbounded_string( no_params );
     end if;
     pushBlock( newScope => true,
       newName => to_string (identifiers( proc_id ).name ) );
     DeclareActualParameters( proc_id );
     expect( is_t );
     if token = separate_t then
        if rshOpt then
           err( "subunits are not allowed in a " & optional_bold( "restricted shell" ) );
        end if;
        expect( separate_t );
        -- "is separate" is effectively an include
        -- only insert include on a syntax check
        if syntax_check then
           insertInclude( identifiers( proc_id ).name & ".sp" );
        end if;
        ParseSeparateProcHeader( proc_id, procStart );
     end if;
     ParseDeclarations;
     expect( begin_t );
     skipBlock;                                       -- never execute now
     pullBlock;
     expect( end_t );
     expect( proc_id );
     procEnd := lastPos+1; -- include EOL ASCII.NUL
     identifiers( proc_id ).value := to_unbounded_string( copyByteCodeLines( procStart, procEnd ) );
     -- fake initial indent of 1 for byte code (SOH)
     -- we don't know what the initial indent is (if any) since it may
     -- not be the first token on the line (though it usually is)
  end if;
  expectSemicolon;
end ParseProcedureBlock;

procedure ParseActualParameters( proc_id : identifier ) is
-- Syntax: (field = declaration [; declaration ... ] )
-- Fields are implemented using records
   expr_value : unbounded_string;
   expr_type : identifier;
   --field_id : identifier;
   --b : boolean;
   no_param : integer;
   found : boolean := false;
begin
  expect( symbol_t, "(" );                                  -- read constant
  no_param := 1;
  loop                                                      -- read values
    ParseExpression( expr_value, expr_type );               -- next element
    -- In a syntax check, the formal parameters aren't created so there's
    -- no reason to look them up.  We're just reading through the parameters
    -- for the procedure call...
    if not syntax_check then
       found := false;
       for j in 1..identifiers_top-1 loop
           if identifiers( j ).field_of = proc_id then
              if integer'value( to_string( identifiers( j ).value )) = no_param then
                 found := true;
                 declare
                    paramName : unbounded_string;
                    formal_param_t : identifier;
                    actual_param_t : identifier;
                 begin
                    formal_param_t := j;
                    if formal_param_t = eof_t then
                       err( "unable to find formal parameter" );
                    else
                       if baseTypesOK( identifiers( formal_param_t ).kind, expr_type ) then
                          paramName := identifiers( j ).name;
                          paramName := delete( paramName, 1, index( paramName, "." ) );
                          --findIdent( fieldName, field_t );
                          declareStandardConstant( actual_param_t,
                              to_string( paramName ),
                              identifiers( formal_param_t ).kind,
                              to_string( expr_value ) );
   --would really be a different declare
                          if isExecutingCommand then
                             identifiers( actual_param_t ).value := expr_value;
                             if trace then
                                put_trace(
                                  to_string( identifiers( formal_param_t ).name ) & " := " &
                                  to_string( expr_value ) );
                             end if;
                          end if;
                       end if;
                    end if;
                 end;
                 exit; -- because found
           end if;
       end if;
       end loop; -- for
       -- we don't know if there are too few (yet)
       if not found then
          err( "parameter not found or too many parameters" );
       end if;
    end if;
    exit when error_found or identifiers( token ).value /= ","; -- more?
    expect( symbol_t, "," );
    no_param := no_param + 1;
  end loop;
  expect( symbol_t, ")" );
end ParseActualParameters;

procedure ParseSeparateFuncHeader( func_id : identifier; funcStart : out natural ) is
  -- Syntax: separate( parent ); function p [(param1...)] return type is
  -- Note: forward declaration handling not yet written so minimal parameter
  -- checking in the header.
  separate_func_id : identifier;
  type_token       : identifier;
  parent_id        : identifier;
  b : boolean;
  pu : unbounded_string;
  i : integer;
  ch : character;
begin
   -- separate
   expectSemicolon;
   expect( separate_t );
   expect( symbol_t, "(");
   ParseIdentifier( parent_id );
   -- NOTE: the identifier token returned has the prefix stripped!  This needs
   -- to be fixed so I cannot check to see if it was full path before stripping.
   i := length( pu );
   while i > 0 loop
     ch := element( pu, i );
     if ch = '.' then
        delete( pu, 1, i );
        exit;
     end if;
     i := i - 1;
   end loop;
   if identifiers( parent_id ).class /= userProcClass and identifiers( parent_id ).class /= userFuncClass and identifiers( parent_id ).class /= mainProgramClass then
         err( "parent should be a subprogram" );
   elsif identifiers( parent_id ).name /= pu then
         err( "expected parent unit " & optional_bold( to_string( pu ) ) );
   end if;
   expect( symbol_t, ")");
   expectSemicolon;
   -- separate's procedure header
   funcStart := firstPos;
   expect( function_t );
   -- could do ParseIdentifier since it should exist but want a more meaningful
   -- message error for a mismatch
   ParseProcedureIdentifier( separate_func_id );
   if identifiers( separate_func_id ).value = identifiers( func_id ).value then
      -- names match?  OK, discard.  proc is stored under original ident
      b := deleteIdent( separate_func_id );
   else
      err( optional_bold( to_string( identifiers( separate_func_id ).name ) ) & " is different from parent file's " & optional_bold( to_string( identifiers( func_id  ).name ) ) );
   end if;
   -- check for forward declarations not yet written so minimal checking here
   -- flush this out if i have time to walk the identifiers list if available
   if token = symbol_t and identifiers( token ).value = "(" then
      expect( symbol_t, "(" );
      while token /= symbol_t and identifiers( token ).value /= ")" and token /= eof_t loop
         getNextToken;
      end loop;
      expect( symbol_t, ")" );
   end if;
   expect( return_t );
   ParseIdentifier( type_token ); -- don't really care
   if identifiers( func_id ).kind /= type_token then
      err( optional_bold( to_string( identifiers( type_token ).name ) ) & " is different from parent file's " & optional_bold( to_string( identifiers( identifiers( func_id ).kind  ).name ) ) );
   end if;
   expect( is_t );
end ParseSeparateFuncHeader;

procedure ParseFunctionBlock is
  -- Syntax: function f OR function p return t is block end p;
  -- Handle procedure declarations, including forward declarations.
  -- Note: DoUserDefinedFunction executes a user-defined function created by
  -- this routine.
  func_id   : identifier;
  funcStart : natural;
  funcEnd   : natural;
  no_params   : integer;
begin
  funcStart := firstPos;
  expect( function_t );
  ParseProcedureIdentifier( func_id );
  identifiers( func_id ).class := userFuncClass;
  identifiers( func_id ).kind := new_t;
  if token = is_t then -- common error
     expect( return_t );
  elsif token /= return_t and not (token = symbol_t and identifiers( token ).value = "(" ) then
     -- the following is only true for a forward declaration
     -- (otherwise PPI will return otherClass)
     if identifiers( func_id ).class = userFuncClass then
        err( "already forward declared " & optional_bold( to_string( identifiers( func_id ).name ) ) );
     end if;
     -- otherwise, nothing special for a forward declaration
  else
     if token = symbol_t and identifiers( token ).value = "(" then
        expect( symbol_t, "(" );
        no_params := 0;
        ParseFormalParameters( func_id, no_params );
        expect( symbol_t, ")" );
     end if;
     ParseFunctionReturnPart( func_id );
     pushBlock( newScope => true,
       newName => to_string (identifiers( func_id ).name ) );
     DeclareActualParameters( func_id );
     expect( is_t );
     if token = separate_t then
        if rshOpt then
           err( "subunits are not allowed in a " & optional_bold( "restricted shell" ) );
        end if;
         expect( separate_t );
        -- "is separate" is effectively an include
        -- only insert include on a syntax check
        if syntax_check then
           insertInclude( identifiers( func_id ).name & ".sf" );
        end if;
        ParseSeparateFuncHeader( func_id, funcStart );
     end if;
     ParseDeclarations;
     expect( begin_t );
     SkipBlock;                                       -- never execute
     pullBlock;
     expect( end_t );
     expect( func_id );
     funcEnd := lastPos+1; -- include EOL ASCII.NUL
     identifiers( func_id ).value := to_unbounded_string( copyByteCodeLines( funcStart, funcEnd ) );
     -- fake initial indent of 1 for byte code (SOH)
     -- we don't know what the initial indent is (if any) since it may
     -- not be the first token on the line (though it usually is)
  end if;
  expectSemicolon;
end ParseFunctionBlock;

procedure DoUserDefinedProcedure( s : unbounded_string ) is
  -- Execute a user-defined procedure.  Based on interpretScript.
  -- procedure_name [(param1 [,param2...])]
  -- Note: ParseProcedureBlock compiles / creates the user-defined procedure.
  -- This routines runs the previously compiled procedure.
  scriptState : aScriptState;
  command     : unbounded_string := s;
  resultName  : unbounded_string;
  results     : unbounded_string;
  proc_id     : identifier;
begin
  -- Interpret parameters
  proc_id := token;
  getNextToken;
  pushBlock( newScope => true,
     newName => to_string (identifiers( proc_id ).name ) );
  if token = symbol_t and identifiers( token ).value = "(" then
     ParseActualParameters( proc_id );
  end if;
  if isExecutingCommand then
     parseNewCommands( scriptState, s );
     results := null_unbounded_string;        -- no results (yet)
     expect( procedure_t );
     ParseIdentifier( proc_id );
     -- we already know the parameter syntax is good so skip to "is"
     while token /= is_t loop
        getNextToken;
     end loop;
     expect( is_t );
     ParseDeclarations;
     expect( begin_t );
     ParseBlock;
     -- Check to see if we're return-ing early
     -- Not pretty, but will work.  This should be improved.
     if exit_block and done_sub and not error_found and not syntax_check then
        done_sub := false;
        exit_block := false;
        done := false;
     end if;
     expect( end_t );
     expect( proc_id );
     expectSemicolon;
     if not done then                     -- not exiting?
         expect( eof_t );                  -- should be nothing else
     end if;
     restoreScript( scriptState );               -- restore original script
  elsif syntax_check and then length( s ) = 0 then
     err( "(forward) procedure declaration not completed" );
  end if;
  pullBlock;
end DoUserDefinedProcedure;

procedure DoUserDefinedFunction( s : unbounded_string; result : out unbounded_string ) is
  -- Execute a user-defined function.  Based on interpretScript.  Return value
  -- for function is result parameter.
  -- function_name [(param1 [,param2...])]
  -- Note: ParseFunctionBlock compiles / creates the user-defined function.
  -- This routines runs the previously compiled function.
  scriptState : aScriptState;
  command     : unbounded_string := s;
  func_id     : identifier;
  return_id   : identifier;
  resultName  : unbounded_string;
  results     : unbounded_string;
begin
  -- Get the name of the function being called
  func_id := token;
  getNextToken;
  -- Parameters will be in the new scope block
  pushBlock( newScope => true,
     newName => to_string (identifiers( func_id ).name ) );
  -- Parameters?  Create storage space in the symbol table
  if token = symbol_t and identifiers( token ).value = "(" then
     ParseActualParameters( func_id );
  end if;
  if isExecutingCommand then
     -- Prepare to execute.  This should probably be a utility function.
     parseNewCommands( scriptState, s );
     results := null_unbounded_string;        -- no results (yet)
     expect( function_t );                    -- function
     ParseIdentifier( func_id );              -- function name
     while token /= is_t loop                 -- skip header - syntax is good
        getNextToken;                         -- and params are declared
     end loop;
     expect( is_t );                          -- is
     ParseDeclarations;                       -- declaration block
     expect( begin_t );                       -- begin
     ParseBlock;                              -- executable block
     -- Check to see if we're return-ing early
     -- Not pretty, but will work.  This should be improved.
     if exit_block and done_sub and not error_found and not syntax_check then
        done_sub := false;
        exit_block := false;
        done := false;
     end if;
     expect( end_t );                         -- end
     expect( func_id );                       -- function_name
     expectSemicolon;
     if not done then                         -- not exiting?
         expect( eof_t );                     -- should be nothing else
     end if;
     -- return value is top-most variable called "return value"
     findIdent( to_unbounded_string( "return value" ), return_id );
     result := identifiers( return_id ).value;
     restoreScript( scriptState );            -- restore original script
  elsif syntax_check and then length( s ) = 0 then
     err( "(forward) function declaration not completed" );
  end if;
  pullBlock;                                  -- discard locals
end DoUserDefinedFunction;

procedure ParseShellCommand is
  -- Syntax: command-word ( expr [,expr...] )
  -- Syntax: command-word param-word [param-word...]
  cmdNameToken : identifier;
  cmdName    : unbounded_string;
  expr_val   : unbounded_string;
  expr_type  : identifier;
  ap         : argumentListPtr;          -- list of parameters to the cmd
  paramCnt   : natural;                  -- number of parameters in ap
  firstParam : aScannerState;
  Success    : boolean;
  exportList : argumentListPtr;          -- exported C-string variables
  exportCnt  : natural := 0;             -- number of exported variables

  procedure exportVariables is
  -- Search for all exported variables and export them to the
  -- environment so that the program we're running can see them.
  -- The search must start at the bottom of the symbol table so
  -- that, in the case of two exported variables with the same
  -- name, the most recent scope will supercede the older
  -- declaration.
  --  The variables exported are stored in exportList/exportCnt.
  -- Under UNIX/Linux, the application is responsible for storing
  -- the exported variables as C-strings.  The list must be cleared
  -- afterward.
  -- Note: this is not very efficient.
    exportPos  : positive := 1;        -- position in exportList
    tempStr    : unbounded_string;
  begin
    -- count the number of exportable variables
    for id in 1..identifiers_top-1 loop
        if identifiers( id ).export and not identifiers( id ).deleted then
           exportCnt := exportCnt+1;
        end if;
    end loop;
    -- if there are exportable variables, export them and place them
    -- in exportList.
    if exportCnt > 0 then
       exportList := new argumentList( 1..positive( exportCnt ) );
       for id in 1..identifiers_top-1 loop
           if identifiers( id ).export and not identifiers( id ).deleted then
              tempStr := identifiers( id ).name & "=" & identifiers( id ).value;
              if trace then
                 put_trace( "exporting '" & to_string( tempStr ) & "'" );
              end if;
              exportList( exportPos ) := new string( 1..length( tempStr )+1 );
              exportList( exportPos ).all := to_string( tempStr ) & ASCII.NUL;
              if putenv( exportList( exportPos ).all ) /= 0 then
                 err( "unable to export " & optional_bold( to_string( identifiers( id ).name) ) );
              end if;
              exportPos := exportPos + 1;
           end if;
       end loop;
    end if;
  end exportVariables;

  procedure clearExportedVariables is
    -- Clear the strings allocated in exportVariables
    -- should individual strings be deallocated?  If so, need to declare
    -- free?  Also, ap list?
    equalsPos : natural;
    result    : integer;
  begin
    if exportCnt > 0 then
       -- Remove exported items from environment O/S environment
       for i in exportList'range loop
           for j in exportList(i).all'range loop
               if exportList(i)(j) = '=' then
                  equalsPos := j;
                  exit;
               end if;
           end loop;
           C_reset_errno; -- freebsd bug: doesn't return result properly
           result := unsetenv( exportList( i )( 1..equalsPos-1 ) & ASCII.NUL );
           if result /= 0 and C_errno /= 0 then
              err( "unable to remove " &
                   optional_bold( exportList( i )( 1..equalsPos-1 ) ) &
                   "from the O/S environment" );
           end if;
       end loop;
       -- Deallocate memory
       for i in exportList'range loop
           free( exportList( i ) );
       end loop;
       free( exportList ); -- deallocate memory
       exportCnt := 0;
    end if;
  end clearExportedVariables;

  procedure clearParamList is
  begin
    for i in ap'range loop
        free( ap( i ) );
    end loop;
    free( ap );
  end clearParamList;

  function isParanthesis return boolean is
  -- check for a paranthesis, skipping any white space in front.
  begin
     skipWhiteSpace;
     return token = symbol_t and identifiers( token ).value = "(";
     -- return script( cmdpos ) = '(';
  end isParanthesis;

  -- Word parsing and Parameter counting

  word         : unbounded_string;
  pattern      : unbounded_string;
  inBackground : boolean;
  wordType     : aShellWordType;

  -- Pipeline parsing

  pipe2Next    : boolean := false;
  pipeFromLast : boolean := false;

  -- I/O Redirection parsing

  expectRedirectInFile        : boolean := false;     -- encountered <
  expectRedirectOutFile       : boolean := false;     -- encountered >
  expectRedirectAppendFile    : boolean := false;     -- encountered >>
  expectRedirectErrOutFile    : boolean := false;     -- encountered 2>
  expectRedirectErrAppendFile : boolean := false;     -- encountered 2>>

  redirectedInputFd           : aFileDescriptor := 0; -- input fd (if not 0)
  redirectedOutputFd          : aFileDescriptor := 0; -- output fd (if not 0)
  redirectedAppendFd          : aFileDescriptor := 0; -- output fd (if not 0)
  redirectedErrOutputFd       : aFileDescriptor := 0; -- err out fd (if not 0)
  redirectedErrAppendFd       : aFileDescriptor := 0; -- err out fd (if not 0)

  result                      : aFileDescriptor;

    procedure externalCommandParameters( ap : out argumentListPtr; list : in out shellWordList.List ) is
     len  : positive;
     theWord : aShellWord;
  begin
     if shellWordList.Length( list ) = 0 then
        ap := new argumentList( 1..0 );
        return;
     end if;
     len := positive( shellWordList.Length( list ) );
     ap := new argumentList( 1..len );
     for i in 1..len loop
         shellWordList.Find( list, long_integer( i ), theWord );
         ap( i ) := new string( 1..positive( length( theWord.word ) + 1 ) );
	 ap( i ).all := to_string( theWord.word ) & ASCII.NUL;
     end loop;
  end externalCommandParameters; 
  
  procedure checkRedirectFile is
    -- Check for a missing file for a redirection operator.  If a file
    -- was expected (according to the flags) but has not appeared, show
    -- an appropriate error message.
  begin
     if expectRedirectOutFile then
        err( "expected > file" );
     elsif expectRedirectInFile then
        err( "expected < file" );
     elsif expectRedirectAppendFile then
        err( "expected >> file" );
     end if;
  end checkRedirectFile;

  wordList   : shellWordList.List;
  shellWord  : aShellWord;
 
  itselfNext : boolean := false;  -- true if a @ was encountered
 
begin

  -- ParseGeneralStatement just did a resumeScanning.  The token should
  -- still be set to the value of the first word.

   -- Loop for all commands in a pipeline.
   
<<next_in_pipeline>>
  -- Reset parsing variables related to a single command

   -- shellWordList.Clear( wordList );                          -- discard params

  -- ParseGeneralStatement has rolled back the scanner after checking for :=.
  -- Reload the next token.

  -- getNextToken;

  -- Expand command variable (if any).  Otherwise, parse the first shell
  -- word.

     cmdNameToken := token;                       -- avoid prob below w/discard
     ParseOneShellWord( wordType, pattern, cmdName, First => true );
     itself := cmdName;                                    -- this is new @

  -- AdaScript Syntax: count the number of parameters, generate an argument
  -- list of the correct length, interpret the parameters "for real".

<<restart_with_itself>>

  inBackground := false;                                 -- assume fg command
  paramCnt := 0;                                         -- params unknown

  if isParanthesis then                                  -- parenthesis?
     -- getNextToken;                                       -- AdaScript syntax
     expect( symbol_t, "(" );                            -- skip paraenthesis
     markScanner( firstParam );                          -- save position
     while not error_found and token /= eof_t loop       -- count parameters
        ParseExpression( expr_val, expr_type );
	shellWordList.Queue( wordList, aShellWord'( normalWord, expr_val, expr_val ) );
	paramCnt := paramCnt + 1;
        if Token = symbol_t and then identifiers( Token ).value = "," then
           getNextToken;
        else
           exit;
        end if;
     end loop;
     expect( symbol_t, ")" );
     if token = symbol_t and identifiers( token ).value = "|" then
        pipe2Next := true;
	getNextToken;
     end if;
     if pipe2Next and onlyAda95 then
        err( "pipelines are not allowed with " & optional_bold( "pragma ada_95" ) );
     end if;
     if token = symbol_t and identifiers(token).value = "&" then
        inbackground := true;
        expect( symbol_t, "&" );
        if pipe2Next then
           err( "no & - piped commands are automatically run in the background" );
        elsif pipeFromLast then
           err( "no & - final piped command always runs in the foreground" );
        end if;
     end if;

  else

    -- Bourne shell parameters
    
     -- discardUnusedIdentifier( token );
    -- Shell-style parameters.  Read a series of "words", counting the params.
    -- Generate an argument list of the correct length and repeat "for real".

     -- count loop
     -- markScanner( firstParam );
     word := null_unbounded_string;

     -- Some arguments, | or @ ? go get them...
     if token /= symbol_t or else identifiers( token ).value /= ";" then
        ParseShellWords( wordList, First => false );
     end if;
     for i in 1..shellWordList.Length( wordList ) loop
        shellWordList.Find( wordList, i, shellWord );
        if shellWord.wordType = semicolonWord then
           shellWordList.Clear( wordList, i );
           exit;
        elsif shellWord.wordType = pipeWord then
           shellWordList.Clear( wordList, i );
           pipe2Next := true;
           exit;
        elsif shellWord.wordType = itselfWord then
           shellWordList.Clear( wordList, i );
           itselfNext := true;
        elsif error_found then
           exit;
        end if;
        if shellWord.wordType = redirectOutWord or
           shellWord.wordType = redirectInWord or
           shellWord.wordType = redirectAppendWord or
           shellWord.wordType = redirectErrOutWord or
           shellWord.wordType = redirectErrAppendWord then
           if onlyAda95 then
              err( "command line redirection not allowed with " &
                   optional_bold( "ada_95" ) & ".  Use set_output / set_input instead" );
           end if;
           expectRedirectOutFile := true;
        elsif expectRedirectOutFile then           -- redirect filenames
           expectRedirectOutFile := false;         -- not in param list
        elsif wordType = redirectErr2OutWord then
           null;                                   -- no file needed
        end if;
     end loop;
     if pipe2Next and onlyAda95 then
        err( "pipelines not allowed with " & optional_bold( "pragma ada_95" ) );
     end if;
     if shellWordList.length( wordList ) > 0 and onlyAda95 then
        err( "Bourne shell parameters not allowed with " &
             optional_bold( "pragma ada_95" ) );
     end if;

     -- create loop
     --resumeScanning( firstParam );

     -- at this point, the token is the first "word".  Discard it if it is
     -- an unused identifier.

     -- At this point, wordList contains a list of shell word parameters for
     -- the command.  This includes redirections, &, and so forth.  Next,
     -- examine all shell arguments, interpreting them and removing
     -- them from the list.  Set up all I/O redirections as required.  When
     -- this loop is finished, only the command parameters should remain the
     -- word list.

     paramCnt := 1;
     while long_integer( paramCnt ) <= shellWordList.Length( wordList ) loop
        shellWordList.Find( wordList, long_integer( ParamCnt ), shellWord );
-- put_line( "  processing = " & paramCnt'img & " - " & shellWord.pattern & " / " & shellWord.word & "/" & shellWord.wordType'img );

        -- There is no check for multiple filenames after redirections.
        -- This behaviour is the same as BASH: "echo > t.t t2.t" will
        -- write t2.t to the file t.t in both BASH and BUSH.

        if expectRedirectOutFile then             -- expecting > file?
           expectRedirectOutFile := false;
           if redirectedAppendFD > 0 then
              err( "cannot redirect using both > and >>" );
           elsif rshOpt then
              err( "cannot redirect > in a " & optional_bold( "restricted shell" ) );
           elsif pipe2Next then
              err( "> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
              redirectedOutputFd := open( to_string( shellWord.word ) & ASCII.NUL,
                 O_WRONLY+O_TRUNC+O_CREAT, 8#644# );
              if redirectedOutputFd < 0 then
                 err( "Unable to open > file: " & OSerror( C_errno ) );
              else
                 result := dup2( redirectedOutputFd, stdout );
                 if result < 0 then
                    close( redirectedOutputFd );
                    redirectedOutputFd := 0;
                    err( "unable to set output: " & OSerror( C_errno ) );
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectInFile then
           expectRedirectInFile := false;         -- expecting < file?
           if pipeFromLast then
              err( "< file should only be after the first pipeline command" );
           elsif isExecutingCommand then
              redirectedInputFd := open( to_string( shellWord.word ) & ASCII.NUL, O_RDONLY, 8#644# );
              if redirectedInputFd < 0 then
                 err( "Unable to open < file: " & OSerror( C_errno ) );
              else
                 result := dup2( redirectedInputFd, stdin );
                 if result < 0 then
                    close( redirectedInputFd );
                    redirectedInputFd := 0;
                    err( "unable to redirect input: " & OSerror( C_errno ) );
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectAppendFile then
           expectRedirectAppendFile := false;
           if redirectedOutputFD > 0 then
              err( "cannot redirect using both > and >>" );
           elsif pipe2Next then
              err( ">> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
              redirectedAppendFd := open( to_string( shellWord.word ) & ASCII.NUL, O_WRONLY+O_APPEND, 8#644# );
              if redirectedAppendFd < 0 then
                 err( "Unable to open >> file: " & OSerror( C_errno ) );
              else
                 result := dup2( redirectedAppendFd, stdout );
                 if result < 0 then
                    close( redirectedAppendFd );
                    redirectedAppendFd := 0;
                    err( "unable to append output: " & OSerror( C_errno ) );
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectErrOutFile then             -- expecting 2> file?
           expectRedirectErrOutFile := false;
           if redirectedErrAppendFD > 0 then
              result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              close( redirectedErrOutputFd );                  -- done with file
              redirectedErrOutputFD := 0;
              err( "cannot redirect using both 2> and 2>>" );
           elsif pipe2Next then
              err( "2> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
              redirectedErrOutputFd := open( to_string( shellWord.word ) & ASCII.NUL,
                 O_WRONLY+O_TRUNC+O_CREAT, 8#644# );
              if redirectedErrOutputFd < 0 then
                 err( "Unable to open 2> file: " & OSerror( C_errno ) );
              elsif rshOpt then
                 err( "cannot redirect 2> in a " & optional_bold( "restricted shell" ) );
              else
                 result := dup2( redirectedErrOutputFd, stderr );
                 if result < 0 then
                    close( redirectedErrOutputFd );
                    redirectedErrOutputFd := 0;
                    err( "unable to set error output: " & OSerror( C_errno ) );
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif expectRedirectErrAppendFile then
           expectRedirectErrAppendFile := false;
           if redirectedErrOutputFD > 0 then
              result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              close( redirectedErrOutputFd );                  -- done with file
              redirectedErrOutputFD := 0;
              err( "cannot redirect using both 2> and 2>>" );
           elsif pipe2Next then
              err( "2>> file should only be after the last pipeline command" );
           elsif isExecutingCommand then
              redirectedErrAppendFd := open( to_string( shellWord.word ) & ASCII.NUL, O_WRONLY+O_APPEND, 8#644# );
              if redirectedErrAppendFd < 0 then
                 err( "Unable to open 2>> file: " & OSerror( C_errno ) );
              else
                 result := dup2( redirectedErrAppendFd, stderr );
                 if result < 0 then
                    close( redirectedErrAppendFd );
                    redirectedErrAppendFd := 0;
                    err( "unable to append error output: " & OSerror( C_errno ) );
                 end if;
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectOutWord then     -- >? expect a file?
           checkRedirectFile;                     -- check for missing file
           expectRedirectOutFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectInWord then      -- < ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectInFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectAppendWord then  -- >> ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectAppendFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectErrOutWord then  -- 2> ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectErrOutFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectErrAppendWord then  -- 2>> ? expect a file
           checkRedirectFile;                     -- check for missing file
           expectRedirectErrAppendFile := true;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = redirectErr2OutWord then  -- expecting 2>&1 file?
           if redirectedErrOutputFD > 0 then       -- no file for this one
              result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              close( redirectedErrOutputFd );                  -- done with file
              redirectedErrOutputFD := 0;
              err( "cannot redirect using two of 2>, 2>> and 2>&1" );
           elsif redirectedErrAppendFD > 0 then       -- no file for this one
              result := dup2( currentStandardError, stderr );  -- restore stderr
              if result < 0 then                              -- check for error
                 err( "unable to restore current error output: " & OSerror( C_errno ) );
              end if;
              close( redirectedErrAppendFd );                  -- done with file
              redirectedErrAppendFD := 0;
              err( "cannot redirect using two of 2>, 2>> and 2>&1" );
           elsif pipe2Next then
              err( "2>&1 file should only be after the last pipeline command" );
           else
              redirectedErrOutputFd := dup2( currentStandardOutput, stderr );
              if redirectedErrOutputFd < 0 then
                 redirectedErrOutputFd := 0;
                 err( "unable to set error output: " & OSerror( C_errno ) );
              end if;
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        elsif shellWord.wordType = ampersandWord then       -- & ?
           if shellWordList.aListIndex( paramCnt ) /= shellWordList.Length( wordList ) then
              err( "unexpected arguments after &" );
           end if;
           inbackground := true;
           if pipe2Next then
              err( "no & - piped commands are automatically run in the background" );
           elsif pipeFromLast then
              err( "no & - final piped command always runs in the foreground" );
           end if;
           shellWordList.Clear( wordList, long_integer( paramCnt ) );
           paramCnt := paramCnt-1;
        end if;
        paramCnt := paramCnt+1;
     end loop;
     checkRedirectFile;                               -- check for missing file

  end if;

  -- End of Parameter Parsing
  
  -- At this point, only the command parameters should remain the word list.
  -- The input/output redirection are in place.  Declare the parameters and
  -- execute the command.

  if isExecutingCommand then                                -- no problems?
     exportVariables;                                       -- make environment

     -- Create a list of C-strings for the parameters

     externalCommandParameters( ap, wordList );

     if boolean(rshOpt) and then Element( cmdName, 1 ) = '/' then    -- rsh & cmd path
        err( "absolute paths to commands not allowed in " &
             optional_bold( "restricted shells" ) );
     elsif not pipeFromLast and pipe2next then              -- first in pipeln?
        run_inpipe( cmdName, cmdNameToken, ap, Success,     -- pipe output
           background => true,
           cache => inputMode /= interactive );
     elsif pipeFromLast and not pipe2next then              -- last in pipeln?
        run_frompipe( cmdName, cmdNameToken, ap, Success,   -- pipe input
           background => false,
           cache => inputMode /= interactive );
        closePipeline;
        -- certain cmds (like "less") need to be cleaned up
        -- with wait4children.  Others are OK.  Why?
        -- wait4children                                    -- (child cleanup)
        -- wait4LastJob?
     elsif pipeFromLast and pipe2next then                  -- inside pipeline?
        run_bothpipe( cmdName, cmdNameToken, ap, Success,   -- pipe in & out
           background => true,
           cache => inputMode /= interactive );
     else                                                   -- no pipeline?
        run( cmdName, cmdNameToken, ap, Success,            -- just run it
           background => inBackground,
           cache => inputMode /= interactive );             -- run the command
     end if;
     clearExportedVariables;                                -- clear environ
     discardUnusedIdentifier( cmdNameToken );               -- drop if not ident
  else                                                      -- cmd failure?

     -- If a pipeline command fails, then commands running in the
     -- background that accept user input will conflict with the
     -- command prompt.  We've got to wait until the final successful
     -- pipe command is finished before returning to the command prompt.
     --   For example, "cat | grep "h" < t.t" will fail because "<" must
     -- be on the first command.  However, cat will already be running
     -- in the background when the error occurs.  BUSH will wait until
     -- ctrl-d is pressed, at which time the user is presented with the
     -- command prompt.  (This is the same behaviour as BASH.)
     --   Background commands do not require special handling.

     if pipeFromLast or pipe2next then                      -- in a pipeline?
        wait4LastJob;                                       -- (child cleanup)
     end if;

  end if;                                                   -- then discard it

  -- If there was command-line redirection, restore standard input/
  -- output to the original destinations.  The original files will
  -- be saved in currentStandardInput/Output.  The redirect flags
  -- should be set properly even if a parsing error occurred.

  if redirectedOutputFd > 0 then                            -- output redirect?
     result := dup2( currentStandardOutput, stdout );       -- restore output
     if result < 0 then                                     -- check for error
        err( "unable to restore current output: " & OSerror( C_errno ) );
     end if;
     close( redirectedOutputFd );                           -- done with file
  elsif redirectedInputFd > 0 then                          -- input redirect?
     result := dup2( currentStandardInput, stdout );        -- restore input
     if result < 0 then                                     -- check for error
        err( "unable to restore current input: " & OSerror( C_errno ) );
     end if;
     close( redirectedInputFd );                            -- done with file
  elsif redirectedAppendFd > 0 then                         -- append redirect?
     result := dup2( currentStandardOutput, stdout );       -- restore output
     if result < 0 then                                     -- check for error
        err( "unable to restore current output: " & OSerror( C_errno ) );
     end if;
     close( redirectedAppendFd );                           -- done with file
  elsif redirectedErrOutputFd > 0 then                      -- errout redirect?
     result := dup2( currentStandardError, stderr );        -- restore stderr
     if result < 0 then                                     -- check for error
        err( "unable to restore current error output: " & OSerror( C_errno ) );
     end if;
     close( redirectedErrOutputFd );                        -- done with file
  elsif redirectedErrAppendFd > 0 then                      -- append redirect?
     result := dup2( currentStandardError, stderr );        -- restore stderr
     if result < 0 then                                     -- check for error
        err( "unable to restore current error output: " & OSerror( C_errno ) );
     end if;
     close( redirectedErrAppendFd );                        -- done with file
  end if;

  -- restore the semi-colon we threw away at the beginning
  -- by this point, Token is eof_t, so we'll have to force it to a ';'
  -- since once Token is eof_t, it's always eof_t in the scanner

  if ap /= null then                                        -- parameter list?
     clearParamList;                                        -- discard it
     shellWordList.Clear( wordList );
  end if;

  -- Comand complete.  Look for next in pipeline (if any).

  pipeFromLast := pipe2Next;                                -- input from out
  if pipeFromLast and not error_found and not done then     -- OK so far?
     pipe2Next := false;                                    -- reset pipe flag
     if not error_found then                                -- found it?
        goto next_in_pipeline;                              -- next piped cmd
     end if;
  end if;

  -- Command ended with @?  Re-run with new parameters...

  if itselfNext then
     itselfNext := false;
     goto restart_with_itself;
  end if;
end ParseShellCommand;


-----------------------------------------------------------------------------
-- RUN AND CAPTURE OUTPUT
--
-- Run the byte code and return the results.  Set fragmement to false if the
-- byte code is a complete script rather than extracted from as a subscript.
-- You usually want to use CompileRunAndCaptureOutput.  The only thing that
-- uses this procedure directly is the prompt script because the byte code
-- is saved.
--
-- BUGS: SHOULD BE REWRITTEN TO USE PIPES INSTEAD OF TEMP FILE
-- based on interpretScript
-----------------------------------------------------------------------------

procedure RunAndCaptureOutput( s : unbounded_string; results : out
  unbounded_string; fragment : boolean := true ) is
  scriptState : aScriptState;
  command     : unbounded_string := s;
  oldStandardOutput : aFileDescriptor;
  resultFile  : aFileDescriptor := -1;
  resultName  : unbounded_string;
  result      : aFileDescriptor;
  unlinkResult : integer;
  ch          : character := ASCII.NUL;
  chars       : long_integer;
begin
  -- saveScript( scriptState );                  -- save current script
-- put_token; -- DEBUG
  results := null_unbounded_string;
  if isExecutingCommand then                               -- only for real
     makeTempFile( resultName );                           -- results filename
     resultFile := open( to_string( resultName ) & ASCII.NUL, -- open results
        O_WRONLY+O_TRUNC, 8#644# );                        -- for writing
     if resultFile < 0 then                                -- failed?
        err( "RunAndCaptureOutput: unable to open file: "&
           OSerror( C_errno ));
     elsif trace then                                      -- trace on?
        put_trace( "results will be captured from file descriptor" &
          resultFile'img );
     end if;
  end if;
  if isExecutingCommand or Syntax_Check then               -- for real or check
     parseNewCommands( scriptState, s, fragment );         -- install cmds
  end if;
  if isExecutingCommand and resultFile > 0 then            -- only for real
     oldStandardOutput := currentStandardOutput;           -- save old stdout
     result := dup2( resultFile, stdout );                 -- redirect stdout
     if result < 0 then                                    -- error?
        err( "unable to set output: " & OSerror( C_errno ) );
     elsif not error_found then                            -- no error?
        currentStandardOutput := resultFile;               -- track fd
     end if;
  end if;
  if isExecutingCommand or Syntax_Check then               -- for real or check
     loop                                                  -- run commands
        ParseGeneralStatement;                             -- general stmts
        exit when done or error_found or token = eof_t;    -- until done, error
      end loop;                                            --  or reached eof
      if not done then                                     -- not done?
         expect( eof_t );                                  -- should be eof
     end if;
  end if;
  -- Read the results.  Don't worry if a syntax check or not.  If we were
  -- redirecting for any reason, get the results and restore standard output
  -- if commands contain a pipeline, there may have been a fork
  -- If this is one of the pipeline commands, we'll be exiting
  -- so check to see that we are still executing something.
  if not done and resultFile > 0 then                   -- redirecting?
     result := dup2( oldStandardOutput, stdout );       -- to original
     if result < 0 then                                 -- error?
        err( "unable to restore stdout: " & OSerror( C_errno ) );
     else                                               -- no error?
        currentStandardOutput := oldStandardOutput;     -- track fd
     end if;
     close( resultFile );                               -- reopen results
     resultFile := open( to_string(resultName) & ASCII.NUL, O_RDONLY,
         8#644# );
     if resultFile < 0 then                                -- error?
        err( "unable to open temp file for reading: " &
           OSError( C_errno ));
     else
        loop                                               -- for all results
<<reread>>
          read( chars, resultFile, ch, 1 );                -- slow (one char)
          if chars = 0 then                                -- read none?
             exit;                                         --   done
          elsif chars < 0 then                             -- error
             if C_errno = EAGAIN or C_errno = EINTR then   -- retry?
                goto reread;                               -- do so
             end if;                                       -- other error?
             err( "unable to read results: " & OSError( C_errno ) );
             exit;                                         --  and bail
          end if;
          results := results & ch;                         -- add to results
        end loop;
        close( resultFile );                               -- close and delete
     end if;
     unlinkResult := unlink( to_string( resultName ) & ASCII.NUL );
     if unlinkResult < 0 then                              -- unable to delete?
        err( "unable to unlink temp file: " & OSError( C_errno ) );
     end if;
     if length( results ) > 0 then                         -- discard last EOL
        if element( results, length( results ) ) = ASCII.LF then
           delete( results, length( results ), length( results ) );
           if length( results ) > 0 then  -- MS-DOS
              if element( results, length( results ) ) = ASCII.CR then
                 delete( results, length( results ), length( results ) );
              end if;
           end if;
        end if;
     end if;
  -- elsif not syntax_check then                              -- 
  --    close( resultFile );
  end if;                                                  -- still executing
  restoreScript( scriptState );                            -- original script
end RunAndCaptureOutput;

-----------------------------------------------------------------------------
-- COMPILE RUN AND CAPTURE OUTPUT
--
-- Compile commands, run the commands and return the results.
-----------------------------------------------------------------------------

procedure CompileRunAndCaptureOutput( commands : unbounded_string; results : out
  unbounded_string ) is
  byteCode : unbounded_string;
  scriptState : aScriptState;
begin
  saveScript( scriptState );               -- save current script
  compileCommand( commands );
  byteCode := to_unbounded_string( script.all );
  if not error_found then
     RunAndCaptureOutput( byteCode, results, fragment => false );
  end if;
  restoreScript( scriptState );            -- restore original script
end CompileRunAndCaptureOutput;

procedure ParseStep is
-- debugger: step one instruction forward.  Do this by activating SIGINT
begin
  expect( step_t );
  if inputMode /= breakout then
     err( "step can only be used when you break out of a script" );
  else
     done := true;
     breakoutContinue := true;
     stepFlag1 := true;
     put_trace( "stepping" );
  end if;
end ParseStep;

procedure ParseReturn is
  -- Syntax: return [function-result-expr]
  -- Return from a subprogram or quit interactive session or resume from a
  -- breakout.
  expr_val   : unbounded_string;
  expr_type  : identifier;
  return_id  : identifier;
begin
  if inputMode = breakout then
     expect( return_t );
     expectSemicolon;
     done := true;
     breakoutContinue := true;
     syntax_check := true;
     put_trace( "returning to script" );
  elsif inputMode = interactive then
     if isLoginShell then
        err( "warning: This is a login shell.  Use " &
             optional_bold( "logout" ) & " to quit." );
     else
        expect( return_t );
        expectSemicolon;
        if isExecutingCommand then
           DoQuit;
        end if;
     end if;
  else
     expect( return_t );
     if token /= eof_t and not (token = symbol_t and identifiers( token ).value = ";") and not (token = symbol_t and identifiers( token ).value = "|" ) then
        if isExecutingCommand then
           -- return value only exists at run-time.  There are better ways to
           -- do this.
           findIdent( to_unbounded_string( "return value" ), return_id );
           if return_id = eof_t then
              err( "procedures cannot return a value" );
           else
           -- at this point, we don't know the function id.  Maybe we can
           -- check the block name and derrive it that way.  Until we do,
           -- no type checking on the function result!
              ParseExpression( expr_val, expr_type );
           --if uniTypesOk( expr_type, uni_numeric_t ) then
              identifiers( return_id ).value := expr_val;
              if trace then
                 put_trace( "returning """ & to_string( expr_val ) & """" );
              end if;
           end if;
              --last_status := aStatusCode( to_numeric( expr_val ) );
              --end if;
        else
              -- for syntax checking, we need to walk the expression
              ParseExpression( expr_val, expr_type );
        end if;
        expectSemicolon;
        if isExecutingCommand then
           DoReturn;
        end if;
     else
        -- no return value?  do return
        expectSemicolon;
        if isExecutingCommand then
           DoReturn;
        end if;
     end if;
  end if;
end ParseReturn;

procedure ParseAssignment is
  -- Basic variable assignment
  -- Syntax: var := expression or array(index) := expr
  var_id     : identifier;
  var_kind   : identifier;
  expr_value : unbounded_string;
  right_type : identifier;
  index_value: unbounded_string;
  index_kind : identifier;
  array_id   : arrayID;
  arrayIndex : long_integer;
begin
  if inputMode = interactive or inputMode = breakout then
    if identifiers( token ).kind = new_t and not onlyAda95 and not restriction_no_auto_declarations then
       ParseNewIdentifier( var_id );
       if token = symbol_t and identifiers( token ).value = "(" then
          err( "cannot automatically declare new arrays" );
          discardUnusedIdentifier( var_id );
          var_id := eof_t;
       end if;
    else
       ParseIdentifier( var_id );
    end if;
  else
    ParseIdentifier( var_id );
  end if;
  itself := identifiers( var_id ).value;
  var_kind := identifiers( var_id ).kind;
  itself_type := var_kind;
  if not class_ok( var_id, otherClass ) then
     null;
  elsif identifiers( var_kind ).limit then
     err( "limited variables cannot be assigned a value" );
  elsif identifiers( var_id ).kind = root_record_t then
     err( "cannot assign to an entire record" );
  elsif identifiers( var_id ).list then

     expect( symbol_t, "(" );
     ParseExpression( index_value, index_kind );
     if getUniType( index_kind ) = uni_string_t or identifiers( index_kind ).list then
        err( "scalar expression expected" );
     end if;
     expect( symbol_t, ")" );
     if isExecutingCommand then
        array_id := arrayID( to_numeric( identifiers( var_id ).value ) );
        arrayIndex := long_integer( to_numeric( index_value ) );
        if inBounds( array_id, arrayIndex ) then
           itself := arrayElement( array_id, arrayIndex );
           itself_type := identifiers( itself_type ).kind;
        else
           err( "Internal error: unable to find array" );
        end if;
     end if;
     var_kind := identifiers( var_kind ).kind; -- array of what?
  end if;
  ParseAssignPart( expr_value, right_type );

  if inputMode = interactive or inputMode = breakout then
     if identifiers( var_id ).kind = new_t and not onlyAda95 and not restriction_no_auto_declarations and not error_found then
        var_kind := right_type;
        identifiers( var_id ).kind := right_type;
        identifiers( var_id ).class := otherClass;
        put_trace( "Assuming " & to_string( identifiers( var_id ).name ) &
           " is a new " & to_string( identifiers( right_type ).name ) &
           " variable" );
      end if;
  end if;
  if baseTypesOk( var_kind, right_type ) then
     if getUniType( var_id ) = uni_numeric_t then
        -- numeric test.  universal typelesses could result
        -- in a non-numeric expression that baseTypesOk
        -- doesn't catch.
        declare
           lf : long_float;
        begin
           if isExecutingCommand then
              lf := to_numeric( expr_value );
	      -- handle integer types
              expr_value := castToType( lf, var_kind );
           end if;
        exception when others =>
           err( "'" & to_string( expr_value) & "' is not numeric" );
        end;
     end if;
     if isExecutingCommand then
        if identifiers( var_id ).list then
           --mem_id := long_integer( to_numeric( identifiers( var_id ).value ) );
           --arrayIndex := long_integer( to_numeric( index_value ) );
           if not inBounds( array_id, arrayIndex ) then
              err( "exception raised" );
           else
              assignElement( array_id, arrayIndex, expr_value );
              if trace then
              put_trace(
                 to_string( identifiers( var_id ).name ) &
                 "(" &
                 to_string( index_value ) &
                 ")" &
                 " := """ &
                 to_string( ToEscaped( expr_value ) ) &
                    """" );
              end if;
           end if;
        else
           identifiers( var_id ).value := expr_value;
           if trace then
              -- builtins.env( ident ) would be better if a value is
              -- returned
              put_trace(
                 to_string( identifiers( var_id ).name ) &
                 " := """ &
                 to_string( ToEscaped( expr_value ) ) &
                 """" );
           end if;
        end if;
    end if;
  end if;
  itself_type := new_t;
end ParseAssignment;

procedure ParseVarDeclaration is
  -- Basic variable declaration
  -- Syntax: var [,var2 ...] declaration_part
  -- Array variables can only be declared one-at-a-time
  var_id  : identifier;
  var2_id : identifier;
  name    : unbounded_string;
  multi   : boolean := false;
  b       : boolean;
begin
   ParseNewIdentifier( var_id );
   if token = symbol_t and identifiers( token ).value = "," then
      expect( symbol_t, "," );
      var2_id := token;
      pragma warnings( off ); -- hide infinite recursion warning
      ParseVarDeclaration;
      multi := true;
      pragma warnings( on );
      if error_found then
         discardUnusedIdentifier( var_id );
      else
         if identifiers( var2_id ).list then
            err( "multiple arrays cannot be declared in one declaration" );
            -- because only the array is assigned values with :=
            -- unless I want to copy all the array elements everytime.
            -- Also, can't overwrite array ident value field.
            b := deleteIdent( var2_id );
         else
            -- OK so far? copy declaration leftward through variable list

            name := identifiers( var_id ).name;
            identifiers( var_id ) := identifiers( var2_id );
            identifiers( var_id ).name := name;

            -- Record type?  Must create fields.

            if identifiers( getBaseType( identifiers( var_id ).kind ) ).kind = root_record_t then  -- record type?
-- put_line( "Recursing for " & identifiers( var_id ).name );
-- put_token;
               ParseRecordDeclaration( var_id, identifiers( var_id ).kind, canAssign => false );
               -- copy values for fields
               declare
                 numFields : natural;
                 source_id, target_id : identifier;
               begin
                 numFields := natural( to_numeric( identifiers( identifiers( var_id ).kind ).value ) );
-- put_line( "Copying " & numFields'img );
                 for i in 1..numFields loop
                     findField( var_id, i, source_id );
                     findField( var2_id, i, target_id );
                     identifiers( source_id ).value := identifiers( target_id ).value;
                 end loop;
               end;
           end if;

         end if;
      end if;
      return;
   end if;
   ParseDeclarationPart( var_id, anon_arrays => true ); -- var id may change...won't effect next stmt
   if error_found then
      discardUnusedIdentifier( var_id );
   end if;
end ParseVarDeclaration;

procedure ParseGeneralStatement is
  -- Syntax: env-cmd | clear-cmd | ...
  expr_value : unbounded_string;
  expr_type  : identifier;
  cmdStart   : aScannerState;
  must_exit  : boolean;
  eof_flag   : boolean := false;
  term_id    : identifier;
  startToken : identifier;
begin

  -- mark start of line (prior to breakout test which will change token
  -- to eof )

  startToken := Token;
  markScanner( cmdStart );
  -- put( "PGS: " ); put_token; -- DEBUG

  -- interrupt handling

  if stepFlag1 then
     stepFlag1 := false;
     stepFlag2 := true;
  elsif stepFlag2 then
     stepFlag2 := false;
     wasSIGINT := true;
  end if;
  if wasSIGINT then                                      -- control-c?
     if inputMode = interactive or inputMode = breakout then -- interactive?
        wasSIGINT := false;                              -- just ignore
     elsif not breakoutOpt then                          -- no breakouts?
        wasSIGINT := false;                              -- clear flag
        DoQuit;                                          -- stop BUSH
     else                                                -- running script?
        for i in 1..identifiers_top-1 loop
            if identifiers( i ).inspect then
               Put_Identifier( i );
            end if;
        end loop;
        err( optional_inverse( "Break: return to continue, logout to quit" ) ); -- show stop posn
     end if;
  elsif wasSIGWINCH then                                 -- window change?
     findIdent( to_unbounded_string( "TERM" ), term_id );
     checkDisplay( identifiers( term_id ).value );       -- adjust size
     wasSIGWINCH := false;
  end if;

  -- Parse the general statement
  --
  -- built-in?

  itself := identifiers( token ).value;
  itself_type := token;

  if Token = command_t then
     err( "Bourne shell command command not implemented" );
     --getNextToken;
     --ParseShellCommand;
  elsif Token = typeset_t then
     ParseTypeSet;
  elsif Token = pragma_t then
     ParsePragma;
  elsif Token = type_t then
     ParseType;
  elsif Token = null_t then
     getNextToken;
  elsif Token = subtype_t then
     ParseSubtype;
  elsif Token = if_t then
     ParseIfBlock;
  elsif Token = case_t then
     ParseCaseBlock;
  elsif Token = while_t then
     ParseWhileBlock;
  elsif Token = for_t then
     ParseForBlock;
  elsif Token = loop_t then
     ParseLoopBlock;
  elsif Token = return_t then
     ParseReturn;
     return;
  elsif Token = step_t then
     ParseStep;
  elsif token = logout_t then
     --if not isLoginShell and inputMode /= interactive and inputMode /= breakout then
     -- ^--not as restrictive
     if not isLoginShell and inputMode /= breakout then
        err( "warning: this is not a login shell: use " & optional_bold( "return" ) &
             " to quit" );
     end if;
     getNextToken;
     expectSemicolon;
     if not error_found or inputMode = breakout then
        DoQuit;
     end if;
     return;
  elsif Token = create_t then
     ParseOpen( create => true );
  elsif Token = open_t then
     ParseOpen;
  elsif Token = close_t then
     ParseClose;
  elsif Token = put_line_t then
     ParsePutLine;
  elsif token = symbol_t and identifiers( token ).value = "?" then
     ParseQuestion;
  elsif Token = put_t then
     ParsePut;
  elsif Token = new_line_t then
     ParseNewLine;
  elsif Token = skip_line_t then
     ParseSkipLine;
  elsif Token = set_input_t then
     ParseSetInput;
  elsif Token = set_output_t then
     ParseSetOutput;
  elsif Token = set_error_t then
     ParseSetError;
  elsif Token = cmd_setexit_t then
     ParseSetExitStatus;
  elsif Token = reset_t then
     ParseReset;
  elsif Token = delete_t then
     getNextToken;
     if token = symbol_t and identifiers( token ).value = "(" then
        resumeScanning( cmdStart );
        ParseDelete;
     else
        discardUnusedIdentifier( token );
        resumeScanning( cmdStart );
        ParseShellCommand;
     end if;
  elsif Token = get_t then
     ParseGet;
  elsif Token = os_system_t then
     ParseOSSystem;
  elsif Token = delay_t then
     ParseDelay;
  elsif Token = locks_lock_t then
     ParseLockLockFile;
  elsif Token = locks_unlock_t then
     ParseLockUnlockFile;
  elsif token = cgi_put_cgi_header_t then               -- CGI.put_cgi_headr
     ParsePut_CGI_Header;
  elsif token = cgi_put_HTML_head_t then                -- CGI.put_html_head
     ParsePut_HTML_Head;
  elsif token = cgi_put_HTML_heading_t then             -- CGI.put_html_heading
     ParsePut_HTML_Heading;
  elsif token = cgi_put_HTML_tail_t then                -- CGI.put_html_tail
     ParsePut_HTML_Tail;
  elsif token = cgi_put_error_message_t then            -- CGI.put_error_msg
     ParsePut_Error_Message;
  elsif token = cgi_put_variables_t then                -- CGI.put_variables
     ParsePut_Variables;
  elsif token = cgi_set_cookie_t then                   -- CGI.set_cookie
     ParseSet_Cookie;
  elsif token = cal_split_t then                        -- Calendar.Split
     ParseCalSplit;
  elsif Token = sound_play_t then
     ParsePlay;
  elsif Token = sound_playcd_t then
     ParsePlayCD;
  elsif Token = sound_stopcd_t then
     ParseStopCD;
  elsif Token = sound_mute_t then
     ParseMute;
  elsif Token = sound_unmute_t then
     ParseUnmute;
  elsif Token = replace_t then
     ParseStringsReplace;
  elsif Token = csv_replace_t then
     ParseStringsCSVReplace;
  elsif Token = set_unbounded_string_t then         -- Strings.set_unbounded_string
     ParseStringsSetUnboundedString;
  elsif Token = split_t then
     ParseStringsSplit;
  elsif token = db_connect_t then                   -- DB.Connect
     ParseDBConnect;
  elsif token = db_disconnect_t then                -- DB.Disconnect
     ParseDBDisconnect;
  elsif token = db_reset_t then                     -- DB.Reset
     ParseDBReset;
  elsif token = db_set_rollback_on_finalize_t then  -- DB.SetRollbackOnFinalize
     ParseDBSetRollbackOnFinalize;
  elsif token = db_open_db_trace_t then             -- DB.OpenDBTrace
     ParseDBOpenDBTrace;
  elsif token = db_close_db_trace_t then            -- DB.CloseDBTrace
     ParseDBCloseDBTrace;
  elsif token = db_set_trace_t then                 -- DB.SetTrace
     ParseDBSetTrace;
  elsif token = db_clear_t then                     -- DB.Clear
     ParseDBClear;
  elsif token = db_prepare_t then                   -- DB.Prepare
     ParseDBPrepare;
  elsif token = db_append_t then                    -- DB.Append
     ParseDBAppend;
  elsif token = db_append_line_t then               -- DB.Append_Line
     ParseDBAppendLine;
  elsif token = db_append_quoted_t then             -- DB.Append_Quoted
     ParseDBAppendQuoted;
  elsif token = db_execute_t then                   -- DB.Execute
     ParseDBExecute;
  elsif token = db_execute_checked_t then           -- DB.Execute_Checked
     ParseDBExecuteChecked;
  elsif token = db_raise_exceptions_t then          -- DB.Raise_Exceptions
     ParseDBRaiseExceptions;
  elsif token = db_report_errors_t then             -- DB.Report_Errors
     ParseDBReportErrors;
  elsif token = db_begin_work_t then                -- DB.Begin_Work
     ParseDBBeginWork;
  elsif token = db_rollback_work_t then             -- DB.Rollback_Work
     ParseDBRollbackWork;
  elsif token = db_commit_work_t then               -- DB.Commit_Work
     ParseDBCommitWork;
  elsif token = db_rewind_t then                    -- DB.Rewind
     ParseDBRewind;
  elsif token = db_fetch_t then                     -- DB.Fetch
     ParseDBFetch;
  elsif token = db_show_t then                      -- DB.Show
     ParseDBShow;
  elsif token = db_list_t then                      -- DB.List
     ParseDBList;
  elsif token = db_schema_t then                    -- DB.Schema
     ParseDBSchema;
  elsif token = db_users_t then                     -- DB.Users
     ParseDBUsers;
  elsif token = db_databases_t then                 -- DB.Databases
     ParseDBDatabases;
  elsif token = mysql_connect_t then                -- MYSQL.Connect
     ParseMySQLConnect;
  elsif token = mysql_disconnect_t then             -- MYSQL.Disconnect
     ParseMySQLDisconnect;
  elsif token = mysql_reset_t then                  -- MYSQL.Reset
     ParseMySQLReset;
  elsif token = mysql_set_rollback_on_finalize_t then  -- MYSQL.SetRollbackOnFinalize
     ParseMySQLSetRollbackOnFinalize;
  elsif token = mysql_open_db_trace_t then          -- MYSQL.OpenDBTrace
     ParseMySQLOpenDBTrace;
  elsif token = mysql_close_db_trace_t then         -- MYSQL.CloseDBTrace
     ParseMySQLCloseDBTrace;
  elsif token = mysql_set_trace_t then              -- MYSQL.SetTrace
     ParseMySQLSetTrace;
  elsif token = mysql_clear_t then                  -- MYSQL.Clear
     ParseMySQLClear;
  elsif token = mysql_prepare_t then                -- MYSQL.Prepare
     ParseMySQLPrepare;
  elsif token = mysql_append_t then                 -- MYSQL.Append
     ParseMySQLAppend;
  elsif token = mysql_append_line_t then            -- MYSQL.Append_Line
     ParseMySQLAppendLine;
  elsif token = mysql_append_quoted_t then          -- MYSQL.Append_Quoted
     ParseMySQLAppendQuoted;
  elsif token = mysql_execute_t then                -- MYSQL.Execute
     ParseMySQLExecute;
  elsif token = mysql_execute_checked_t then        -- MYSQL.Execute_Checked
     ParseMySQLExecuteChecked;
  elsif token = mysql_raise_exceptions_t then       -- MYSQL.Raise_Exceptions
     ParseMySQLRaiseExceptions;
  elsif token = mysql_report_errors_t then          -- MYSQL.Report_Errors
     ParseMySQLReportErrors;
  elsif token = mysql_begin_work_t then             -- MYSQL.Begin_Work
     ParseMySQLBeginWork;
  elsif token = mysql_rollback_work_t then          -- MYSQL.Rollback_Work
     ParseMySQLRollbackWork;
  elsif token = mysql_commit_work_t then            -- MYSQL.Commit_Work
     ParseMySQLCommitWork;
  elsif token = mysql_rewind_t then                 -- MYSQL.Rewind
     ParseMySQLRewind;
  elsif token = mysql_fetch_t then                  -- MYSQL.Fetch
     ParseMySQLFetch;
  elsif token = mysql_show_t then                   -- MYSQL.Show
     ParseMySQLShow;
  elsif token = mysql_list_t then                   -- MYSQL.List
     ParseMySQLList;
  elsif token = mysql_schema_t then                 -- MYSQL.Schema
     ParseMySQLSchema;
  elsif token = mysql_users_t then                  -- MYSQL.Users
     ParseMySQLUsers;
  elsif token = mysql_databases_t then               -- MYSQL.Databases
     ParseMySQLDatabases;
  elsif token = numerics_set_re_t then              -- Set_Re (complex)
     ParseNumericsSetRe;
  elsif token = numerics_set_im_t then              -- Set_Im (complex)
     ParseNumericsSetIm;
  elsif token = arrays_bubble_sort_t then           -- Bubble_Sort
     ParseArraysBubbleSort;
  elsif token = arrays_bubble_sort_descending_t then  -- Bubble_Sort_Desc
     ParseArraysBubbleSortDescending;
  elsif token = arrays_heap_sort_t then             -- Heap_Sort
     ParseArraysHeapSort;
  elsif token = arrays_heap_sort_descending_t then  -- Heap_Sort_Desc
     ParseArraysHeapSortDescending;
  elsif token = arrays_shuffle_t then               -- Shuffle
     ParseArraysShuffle;
  elsif token = arrays_flip_t then                  -- Flip
     ParseArraysFlip;
  elsif token = arrays_rotate_left_t then           -- Rotate_Left
     ParseArraysRotateLeft;
  elsif token = arrays_rotate_right_t then          -- Rotate_Left
     ParseArraysRotateRight;
  elsif token = arrays_shift_left_t then            -- Shift_Left
     ParseArraysShiftLeft;
  elsif token = arrays_shift_right_t then           -- Shift_Right
     ParseArraysShiftRight;
  -- elsif token = sdl_init_t then                     -- SDL.Init
  --    ParseSDLInit;
  -- elsif token = sdl_quit_t then                     -- SDL.Quit
  --    ParseSDLQuit;
  elsif token = pen_set_rect_t then                -- Pen.Set_Rect
     ParsePenSetRect;
  elsif token = pen_offset_rect_t then             -- Pen.Offset_Rect
     ParsePenOffsetRect;
  elsif token = pen_inset_rect_t then              -- Pen.Inset_Rect
     ParsePenInsetRect;
  elsif token = pen_intersect_rect_t then          -- Pen.Intersect_Rect
     ParsePenIntersectRect;
  elsif token = pen_set_pen_mode_t then            -- Pen.Set_Pen_Mode
     ParsePenSetPenMode;
  elsif token = pen_set_pen_ink_t then             -- Pen.Set_Pen_Ink
     ParsePenSetPenInk;
  elsif token = pen_set_pen_brush_t then           -- Pen.Set_Pen_Brush
     ParsePenSetPenBrush;
  elsif token = pen_set_pen_pattern_t then         -- Pen.Set_Pen_Pattern
     ParsePenSetPenPattern;
  elsif token = pen_move_to_t then                 -- Pen.Move_To
     ParsePenMoveTo;
  elsif token = pen_move_t then                    -- Pen.Move
     ParsePenMove;
  elsif token = pen_line_to_t then                 -- Pen.Line_To
     ParsePenLineTo;
  elsif token = pen_line_t then                    -- Pen.Line
     ParsePenLine;
  elsif token = pen_hline_t then                   -- Pen.HLine
     ParsePenHLine;
  elsif token = pen_vline_t then                   -- Pen.VLine
     ParsePenVLine;
  elsif token = pen_frame_rect_t then              -- Pen.Frame_Rect
     ParsePenFrameRect;
  elsif token = pen_paint_rect_t then              -- Pen.Paint_Rect
     ParsePenPaintRect;
  elsif token = pen_fill_rect_t then               -- Pen.Fill_Rect
     ParsePenFillRect;
  elsif token = pen_frame_ellipse_t then           -- Pen.Fill_Ellipse
     ParsePenFrameEllipse;
  elsif token = pen_fill_ellipse_t then            -- Pen.Fill_Ellipse
     ParsePenFillEllipse;
  elsif token = pen_clear_t then                   -- Pen.Clear
     ParsePenClear;
  elsif token = pen_new_screen_canvas_t then       -- Pen.New_Screen_Canvas
     ParsePenNewScreenCanvas;
  elsif token = pen_new_window_canvas_t then       -- Pen.New_Window_Canvas
     ParsePenNewWindowCanvas;
  elsif token = pen_new_gl_window_canvas_t then    -- Pen.New_GL_Window_Canvas
     ParsePenNewGLWindowCanvas;
  elsif token = pen_new_canvas_t then              -- Pen.New_Canvas
     ParsePenNewCanvas;
  elsif token = pen_wait_to_reveal_t then          -- Pen.Wait_To_Reveal
     ParsePenWaitToReveal;
  elsif token = pen_reveal_t then                  -- Pen.Reveal
     ParsePenReveal;
  elsif token = pen_reveal_now_t then              -- Pen.Reveal_Now
     ParsePenRevealNow;
  elsif token = pen_get_pen_ink_t then             -- Pen.Get_Pen_Ink
     ParsePenGetPenInk;
  elsif token = pen_set_title_t then               -- Pen.Set_Title
     ParsePenSetTitle;
  elsif token = pen_blend_t then                   -- Pen.Blend
     ParsePenBlend;
  elsif token = pen_fade_t then                    -- Pen.Fade
     ParsePenFade;
  elsif token = pen_close_canvas_t then            -- Pen.Close_Canvas
     ParsePenCloseCanvas;
  elsif token = dirops_change_dir_t then           -- Dir_Ops.Change_Dir
     ParseDirOpsChangeDir;
  elsif token = dirops_make_dir_t then             -- Dir_Ops.Make_Dir
     ParseDirOpsMakeDir;
  elsif token = dirops_remove_dir_t then           -- Dir_Ops.Remove_Dir
     ParseDirOpsRemoveDir;
  elsif Token = else_t then
     err( "else without if" );
  elsif Token = elsif_t then
     err( "elsif without if" );
  elsif Token = with_t then
     err( "with not implemented" );
  elsif Token = use_t then
     err( "use not implemented" );
  elsif Token = task_t then
     err( "tasks not implemented" );
  elsif Token = protected_t then
     err( "protected types not implemented" );
  elsif Token = package_t then
     err( "packages not implemented" );
  elsif Token = exit_t then
     if blocks_top = block'first then           -- not complete. should check
         err( "no enclosing loop to exit" );    -- not just for no blocks
     end if;                                    -- but the block type isn't easily checked
     expect( exit_t );
     if token = when_t or token = if_t then     -- if to give "expected when"
        expect( when_t );
        ParseExpression( expr_value, expr_type );
        if baseTypesOk( boolean_t, expr_type ) then
           must_exit :=  expr_value = "1";
        end if;
     else
        must_exit := true;
     end if;
     if isExecutingCommand and must_exit then
        exit_block := true;
        if trace then
           put_trace( "exiting" );
        end if;
     end if;
  elsif Token = declare_t then
     ParseDeclareBlock;
  elsif Token = begin_t then
     ParseBeginBlock;
  elsif token = word_t then
     -- discardUnusedIdentifier( token );
     resumeScanning( cmdStart );
     ParseShellCommand;
  elsif token = backlit_t then
     err( "unexpected backquote literal" );
  elsif token = procedure_t then
     err( "declare procedures in declaration sections" );
  elsif token = function_t then
     err( "declare functions in declaration sections" );
  elsif Token = eof_t then
     eof_flag := true;
     -- a script could be a single comment without a ;
  elsif Token = symbol_t and identifiers( token ).value = "@" then
     err( "@ must appear after a command or in an assignment expression" );
  elsif not identifiers( Token ).deleted and identifiers( Token ).list then     -- array variable
     resumeScanning( cmdStart );           -- assume array assignment
     ParseAssignment;                      -- looks like a AdaScript command
     itself_type := new_t;                 -- except for token type...
  elsif not identifiers( Token ).deleted and identifiers( token ).class = userProcClass then
     DoUserDefinedProcedure( identifiers( token ).value );
  else

     -- we need to check the next token then back up
     -- should really change scanner to double symbol look ahead?

     getNextToken;

     -- declarations

     if Token = symbol_t and
        (to_string( identifiers( token ).value ) = ":" or
        to_string( identifiers( token ).value ) = ",") then
        resumeScanning( cmdStart );
        ParseVarDeclaration;
     else

        -- assignments
        --
        -- for =, will be treated as a command if we don't force an error
        -- here for missing :=, since it was probably intended as an assignment

        if Token = symbol_t and to_string( identifiers( token ).value ) = "=" then
           expect( symbol_t, ":=" );
        elsif Token = symbol_t and to_string( identifiers( token ).value ) = ":=" then
           resumeScanning( cmdStart );
           ParseAssignment;
           itself_type := new_t;
        else

           -- assume it's a shell command and run it
           -- current token is first "token" of parameter.  Blow it away
           -- if able (ie. "ls file", current token is file but we don't
           -- need that in our identifier list.)

           discardUnusedIdentifier( token );
           resumeScanning( cmdStart );
           ParseShellCommand;
        end if;
     end if;
  end if;
  if not eof_flag then
     if token = symbol_t and identifiers( token ).value = "@" then
        if onlyAda95 then
           err( "@ is not allowed with " & optional_bold( "pragma ada_95" ) );
           -- move to next token or inifinite loop if done = true
           getNextToken;
        elsif itself_type = new_t then
           err( "@ is not defined" );
           getNextToken;
        -- shell commands have no class so we can't do this (without
        -- changes, anyway...)
        --elsif class_ok( itself_type, procClass ) then -- lift this?
        else
           token := itself_type;
           if identifiers( token ).class = otherClass then
              -- not a procedure or keyword? restore value
              identifiers( token ).value := itself;
           end if;
        end if;
     else
        itself_type := new_t;
        expectSemicolon;
     end if;
  end if;

  -- breakout handling
  --
  -- Breakout to a prompt if there was an error and --break is used.
  -- Don't break out if syntax checking or the error was caused while
  -- in the break out command prompt.

  if error_found and then boolean(breakoutOpt) then
     if not syntax_check and inputMode /= breakout then
     declare                                          -- we need to save
        saveMode    : anInputMode := inputMode;       -- BUSH's state
        scriptState : aScriptState;                   -- current script
     begin
        wasSIGINT := false;                            -- clear sig flag
        saveScript( scriptState );                     -- save position
        error_found := false;                          -- not a real error
        script := null;                                -- no script to run
        inputMode := breakout;                         -- now interactive
        interactiveSession;                            -- command prompt
        restoreScript( scriptState );                  -- restore original script
        if breakoutContinue then                       -- continuing execution?
           resumeScanning( cmdStart );                 -- start of command
           err( optional_inverse( "resuming here" ) ); -- redisplay line
           done := false;                              --   clear logout flag
           error_found := false;                       -- not a real error
           exit_block := false;                        --   and don't exit
           syntax_check := false;
           breakoutContinue := false;                  --   we handled it
        end if;
        inputMode := saveMode;                         -- restore BUSH's
        resumeScanning( cmdStart );                    --   overwrite EOF token
     end;
     end if;
  end if;
exception when symbol_table_overflow =>
  err( optional_inverse( "too many identifiers (symbol table overflow)" ) );
when block_table_overflow =>
  err( optional_inverse( "too many nested statements/blocks (block table overflow)" ) );
end ParseGeneralStatement;

procedure ParseMainProgram is
  program_id : identifier;
begin
  expect( procedure_t );
  ParseNewIdentifier( program_id );
  identifiers( program_id ).kind := identifiers'first;
  identifiers( program_id ).class := mainProgramClass;
  --identifiers( program_id ).kind := keyword_t; -- not really, but will do for now!
  pushBlock( newScope => true,
    newName => to_string (identifiers( program_id ).name ) );
  -- Note: pushBlock must be before "is" (single symbol look-ahead)
  expect( is_t );
  ParseDeclarations;
  expect( begin_t );
  ParseBlock;
  pullBlock;
  expect( end_t );
  expect( program_id );
end ParseMainProgram;

------------------------------------------------------------------------------
-- PARSE
--
-- Initiate parsing a compiled set of AdaScript commands.  The commands should
-- have been compiled by interpretCommands or interpretScript.  This subprogram
-- doesn't compile byte code.  error_found will be true if the commands failed
-- because of errors.
------------------------------------------------------------------------------

procedure parse is
begin
  if not error_found then
     cmdpos := firstScriptCommandOffset;
     token := identifiers'first;                -- dummy, replaced by g_n_t
     getNextToken;                              -- load first token
     while (not error_found and not done) and (token = procedure_t or
       token = pragma_t or token = trace_t) loop
        if token = pragma_t then
           ParsePragma;
           expectSemicolon;
        elsif token = procedure_t then
           ParseMainProgram;
           expectSemicolon;
           expect( eof_t );                        -- should be nothing else
           exit;
        elsif token = trace_t then
           ParseShellCommand;
           expectSemicolon;
        end if;
     end loop;
     if not done or token = eof_t then
        loop
          ParseGeneralStatement;                   -- process the first statement
          exit when done or token = eof_t;         -- continue until done
        end loop;                                  --  or eof hit
        if not done then                           -- not exiting?
           expect( eof_t );                        -- should be nothing else
        end if;
     end if;
  end if;
end parse;


------------------------------------------------------------------------------
-- PARSE NEW COMMANDS
--
-- Switch to a new set of commands.  This is used for user-defined procedures,
-- functions and back quoted commands.  It is up to the caller to restore the
-- scanner state.
------------------------------------------------------------------------------

procedure parseNewCommands( scriptState : out aScriptState; commands : unbounded_string; fragment : boolean := true ) is
begin
  saveScript( scriptState );                -- save current script
  if fragment then                          -- a fragment of byte code?
     replaceScriptWithFragment( commands ); -- install proc as script
  else                                      -- otherwise a complete script?
     replaceScript( commands );             -- install proc as script
  end if;
  -- put_line( toEscaped( to_unbounded_string( script.all ) ) ); -- DEBUG
  inputMode := fromScriptFile;             -- running a script
  error_found := false;                    -- no error found
  exit_block := false;                     -- not exit-ing a block
  cmdpos := firstScriptCommandOffset;      -- start at first char
  token := identifiers'first;              -- dummy, replaced by g_n_t
  getNextToken;                            -- load first token
end parseNewCommands;


---------------------------------------------------------
-- END OF ADASCRIPT PARSER
---------------------------------------------------------

------------------------------------------------------------------------------
-- Running stuff
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- INTERACTIVE SESSION
--
-- Begin an interactive session, processing a set of commands typed in by the
-- user.  Handle SIGINT at the command prompt as well as restoring standard
-- output/etc. as required so that lines can be typed in from the console.
-- Continue until the done flag is set.
--   This is run by parse, as the command line options dictate.  This is also
-- used to start a debugging session on interactive breakout.
------------------------------------------------------------------------------

procedure interactiveSession is
  command : unbounded_string;
  result : aFileDescriptor;
begin
  loop                                        -- repeatedly
    updateJobStatus;                          -- cleanup any background jobs
    error_found := false;                     -- no err for prompt
    if length( promptScript ) = 0 then
       prompt := defaultPrompt;
       if terminalWindowNaming then
          put( ASCII.ESC & "]2;" & "SparForte" & ASCII.BEL  ); -- xterm window title
       end if;
    else
       prompt := null_unbounded_string;
       CompileRunAndCaptureOutput( promptScript, prompt );
       if terminalWindowNaming then
          put( ASCII.ESC & "]2;" );
          for i in 1..length( prompt ) loop
              if is_graphic( element( prompt, i ) ) then
                 put( element( prompt, i  ) );
              elsif element( prompt, i ) = ASCII.LF then -- and CR?
                 put( ' ' );
              end if;
           end loop;
           put( ASCII.BEL  ); -- xterm window title
       end if;
    end if;
    put_bold( prompt );                       -- show prompt in bold
    wasSIGINT := false;                       -- clear for getLine
    getLine( command, keepHistory => true );  -- read command from keyboard
    if wasSIGINT then                         -- control-c?
       command := null_unbounded_string;      -- pretend empty command
       wasSIGINT := false;                    -- we handled it
       new_line;                              -- user didn't push enter
    end if;
    -- has user redirected standard in/out/error? then redirect them for
    -- the duration of execution of the commands (and restore the original
    -- values later)
    if currentStandardInput /= originalStandardInput then
       result := dup2( currentStandardInput, stdin );   -- restore stdin
       if result < 0 then
          put_line( standard_error, "Unable to redirect standard input" );
       end if;
    end if;
    if currentStandardOutput /= originalStandardOutput then
       result := dup2( currentStandardOutput, stdout ); -- restore stdout
       if result < 0 then
          put_line( standard_error, "Unable to redirect standard output" );
       end if;
    end if;
    if currentStandardError /= originalStandardError then
       result := dup2( currentStandardError, stderr );  -- restore stderr
       if result < 0 then
          put_line( standard_error, "Unable to redirect standard error" );
       end if;
    end if;
    error_found := false;                               -- no err found (prompt)
    exit_block := false;                                -- not exit-ing a block
    fixSpacing( command );                              -- strip leading/trailing spaces
    if length( command ) > 0 then                       -- something there?
       if Element( command, length( command ) ) /= ';' then -- missing ending ;?
          command := command & ";";                     -- it's implicit so add it
       elsif length( command ) > 1 then
          if Element( command, length( command )-1) = '\' then
             command := command & ";";
          end if;
       end if;                                          -- w/space in case shell cmd
       sourceFilesList.Clear( SourceFiles );
       sourceFilesList.Push( SourceFiles, aSourceFile'( pos => 0, name => to_unbounded_string( commandLineSource ) ) );
       compileCommand( command );
       if not error_found then
          cmdpos := firstScriptCommandOffset;           -- start at first char
          token := identifiers'first;                   -- dummy, replaced by g_n_t
          getNextToken;                                 -- load first token
          while token /= eof_t and not error_found loop
             ParseGeneralStatement;                     -- do the command
          end loop;
       end if;
    end if;
    -- restore original standard input, output, error for the command line
    result := dup2( originalStandardInput, stdin );   -- restore standard input
    if result < 0 then
       put_line( standard_error, "Unable to restore standard input" );
    end if;
    result := dup2( originalStandardOutput, stdout ); -- restore standard output
    if result < 0 then
       put_line( standard_error, "Unable to restore standard output" );
    end if;
    result := dup2( originalStandardError, stderr );  -- restore standard error
    if result < 0 then
       put_line( standard_error, "Unable to restore standard error" );
    end if;
    exit when done;                                   -- and stop when done
  end loop;
end interactiveSession;


------------------------------------------------------------------------------
-- INTERPRET SCRIPT
--
-- Load a script, compile byte code, perform a syntax check (if needed) and
-- execute the script (if needed).  If -e, scriptPath is a string of commands.
-- This is run by parse, as the command line options dictate.
--
-- scriptPath: a script to run, or a string of commands (-e).
------------------------------------------------------------------------------

procedure BUSH_interpretScript( C_scriptPath : C_path ) is
begin
  interpretScript( To_Ada( C_scriptPath ) );
end BUSH_interpretScript;

procedure interpretScript( scriptPath : string ) is
  firstLine : aliased unbounded_string;
begin
  if syntax_check then
     if verboseOpt then
        Put_Trace( "Checking Syntax" );
     end if;
  else
     if verboseOpt then
        Put_Trace( "Executing Script" );
     end if;
  end if;
  inputMode := fromScriptFile;                     -- running a script
  if execOpt then                                  -- -e?
     if verboseOpt then
        Put_Trace( "Compiling Byte Code" );
     end if;
     -- put( ASCII.ESC & "]2;" & "bush" & ASCII.BEL  ); -- xterm window title
     sourceFilesList.Clear( SourceFiles );
     sourceFilesList.Queue( SourceFiles, aSourceFile'(pos => 0, name => to_unbounded_string (commandLineSource) ) );
     scriptFilePath := to_unbounded_string( commandLineSource ); -- script name
     compileCommand( to_unbounded_string( ScriptPath ) ); -- path is really script
  else                                             -- else path is a path
    --put( ASCII.ESC & "]2;" & scriptPath & ASCII.BEL  ); -- xterm window title
    scriptFilePath := to_unbounded_string( scriptPath ); -- script name
    if syntax_check then
       -- only register source files during the syntax check, when files
       -- (including include files) are loaded
       sourceFilesList.Clear( SourceFiles );
       sourceFilesList.Queue( SourceFiles, aSourceFile'(pos => 0, name => scriptFilePath) );
    end if;
    scriptFile := open( scriptPath & ASCII.NUL, 0, 660 ); -- open script
    if scriptFile < 1 then                           -- error?
       scriptFilePath := scriptFilePath & ".sp";   -- try name with ".sp"
       scriptFile := open( scriptPath & ".sp" & ASCII.NUL, 0, 660 );
       if scriptFile < 1 then                           -- error?
          scriptFilePath := scriptFilePath & ".bush";   -- try name with ".bush"
          scriptFile := open( scriptPath & ".bush" & ASCII.NUL, 0, 660 );
       end if;
    end if;
    if scriptFile > 0 then                           -- good?
       error_found := false;                         -- no error found
       exit_block := false;                          -- not exit-ing a block
       if not LineRead( firstLine'access ) then        -- read first line
          put_line( standard_error, "unable to read first line of script" );
          error_found := true;
          goto error;                                -- and interpreting
       end if;
       if script = null then
          if verboseOpt then
             Put_Trace( "Compiling Byte Code" );
          end if;
          compileScript( firstline );
       end if;
    end if;
  end if;
  if (scriptFile > 0 or boolean(execOpt)) and not done then -- file open or -e?
     parse;
  elsif C_errno = 2 then                             -- file not found?
     put_line( standard_error, "unable to open script file '" &
       scriptPath & "' : file not found" );
       error_found := true;
  elsif C_errno /= 0 then                          -- some other error?
     -- use /= 0 in case user aborts with control-c
     put_line( standard_error, "unable to open script file '" &
       scriptPath & "' : " & OSerror( C_errno ) );
       error_found := true;
  end if;
<<error>>
  if error_found then                              -- was there an error?
     if last_status = 0 then                       -- no last command status?
        set_exit_status( Failure );                -- just set to 1
        if trace then
           put_trace("Script exit status is" & failure'img );
        end if;
     else                                          -- otherwise
        set_exit_status( exit_status( last_status ) ); -- return last status
        if trace then
           put_trace("Script exit status is" & last_status'img );
        end if;
     end if;
  else                                             -- no error?
     set_exit_status( 0 );                         -- return no error
     if trace then                                 -- -x? show 0 exit status
        put_trace("Script exit status is 0" );
     end if;
  end if;
  if not execOpt then                              -- not -e?
     close( scriptFile );                          -- close the script file
  end if;

end interpretScript;


------------------------------------------------------------------------------
-- INTERPRET COMMANDS
--
-- Compile string of commands into byte code, perform a syntax check (if
-- needed) and execute the script (if needed).
-- This is run by parse, as the command line options dictate.
--
-- commandString: a string of uncompressed commands (e.g. from -e).
------------------------------------------------------------------------------

procedure BUSH_interpretCommands( C_commandString : C_cmds ) is
begin
   interpretCommands( To_Ada( C_commandString ) );
end BUSH_interpretCommands;

procedure interpretCommands( commandString : string ) is
begin
  interpretCommands( to_unbounded_string( commandString ) );
end interpretCommands;

procedure interpretCommands( commandString : unbounded_string ) is
begin
  if syntax_check then
     if verboseOpt then
        Put_Trace( "Checking Syntax" );
     end if;
  else
     if verboseOpt then
        Put_Trace( "Executing Commands" );
     end if;
  end if;
  if verboseOpt then
     Put_Trace( "Compiling Byte Code" );
  end if;
  scriptFilePath := to_unbounded_string( commandLineSource ); -- "script" name
  sourceFilesList.Clear( SourceFiles );
  sourceFilesList.Push( SourceFiles, aSourceFile'( pos => 0, name => basename( scriptFilePath ) ) );
  compileCommand( commandString );
  parse;
  if error_found then                              -- was there an error?
     if last_status = 0 then                       -- no last command status?
        set_exit_status( Failure );                -- just set to 1
        if trace then
           put_trace("Command string exit status is" & failure'img );
        end if;
     else                                          -- otherwise
        set_exit_status( exit_status( last_status ) ); -- return last status
        if trace then
           put_trace("Command string exit status is" & last_status'img );
        end if;
     end if;
  else                                             -- no error?
     set_exit_status( 0 );                         -- return no error
     if trace then
        put_trace("Command string exit status is 0" );
     end if;
  end if;
end interpretCommands;


procedure SetStandardVariables is
  -- Define variables that cannot be setup by the scanner.
begin

  -- Standard_Input, Standard_Output and Standard_Error have the
  -- form of a typical file variable.

  DoInitFileVariableFields( standard_input_t, originalStandardInput,
    "<standard input>", in_file_t );
  DoInitFileVariableFields( standard_output_t, originalStandardOutput,
    "<standard output>", out_file_t );
  DoInitFileVariableFields( standard_error_t, originalStandardError,
    "<standard error>", out_file_t );

  -- Current_Input, Current_Output and Current_Error are aliases for
  -- another file (by default, Standard_Input/Output/Error ).

  identifiers( current_input_t ).value :=
    to_unbounded_string( standard_input_t'img );
  identifiers( current_output_t ).value :=
    to_unbounded_string( standard_output_t'img );
  identifiers( current_error_t ).value :=
    to_unbounded_string( standard_error_t'img );

end SetStandardVariables;


procedure doGlobalProfile is
  save_rshOpt  : commandLineOption;              -- for executing profile
  save_execOpt : commandLineOption;              -- for executing profile
begin
  save_rshOpt := rshOpt;                   -- if restricted shell
  save_execOpt := execOpt;                 -- if cmd line script
  rshOpt := false;                         -- turn off for profile
  if scriptFile > 0 then                       -- good?
     close( scriptFile );                      -- close test fd
     interpretScript( "/etc/bush_profile" );   -- run login script
  end if;
  rshOpt := save_rshOpt;                          -- restore rsh setting
  execOpt := save_execOpt;                        -- restore -e setting
end doGlobalProfile;


procedure doLocalProfile is
  save_rshOpt  : commandLineOption;              -- for executing profile
  save_execOpt : commandLineOption;              -- for executing profile
  home_id      : identifier;                     -- HOME variable
begin
  save_rshOpt := rshOpt;                   -- if restricted shell
  save_execOpt := execOpt;                 -- if cmd line script
  rshOpt := false;                         -- turn off for profile
  findIdent( to_unbounded_string( "HOME" ), home_id );
  if home_id /= eof_t then                     -- HOME defined?
     scriptFilePath := identifiers( home_id ).value;
     if Element( scriptFilePath, length( scriptFilePath ) ) /= '/' then
        scriptFilePath := scriptFilePath & "/";
     end if;
     scriptFilePath := scriptFilePath & ".sparforte_profile";
     scriptFile := open( to_string( scriptFilePath ) & ASCII.NUL, 0, 660 ); -- open script
     if scriptFile > 0 then                       -- profile opened OK?
        close( scriptFile );                      -- close test fd
        interpretScript( to_string( scriptFilePath ) ); -- do profile
     end if;
  end if;
  rshOpt := save_rshOpt;                          -- restore rsh setting
  execOpt := save_execOpt;                        -- restore -e setting
end doLocalProfile;

procedure checkAndInterpretScript( fullScriptPath : string ) is
begin
  if syntaxOpt then                                  -- -c / --check?
     syntax_check := true;                           -- check syntax only
     interpretScript( fullScriptPath );    -- check the script
  -- no syntax check obsolete with BUSH 2.0 (syntax check stage is needed to
  -- load "include" files)
  --elsif nosyntaxOpt then                             -- -n / --nocheck?
  --   if traceOpt then                                -- -x / --trace?
  --      trace := true;                               -- turn on trace
  --   end if;
  --   interpretScript( Argument( OptionOffset ) );    -- run the script
  else
     syntax_check := true;                           -- check syntax only
     interpretScript( fullScriptPath );    -- check the script
     if not error_found then                         -- no errors?
        resetScanner;                                -- discard declarations
        SetStandardVariables;                        -- built-in elaboration
        if traceOpt then                             -- -x?
           trace := true;                            -- turn on trace
        end if;
        interpretScript( fullScriptPath ); -- run the script
     end if;
     if length( depreciatedMsg ) > 0 then            -- pragma depreciated?
        put( standard_error, scriptFilePath );       -- show the message
        put( standard_error, ":" );                  -- as a warning
        put( standard_error, getLineNo'img );
        put( standard_error, ":" );
        put_line( standard_error, "warning--" & depreciatedMsg );
     end if;
     if processingTemplate then                      -- doing a template
        if verboseOpt then
           Put_Trace( "Processing template " & to_string( templatePath ) );
        end if;
        begin
           processTemplate;
        exception
        when STATUS_ERROR =>
           err( "cannot open template " & optional_bold( to_string( templatePath ) ) &
               " - file may be locked" );
        when NAME_ERROR =>
           err( "template " & optional_bold( to_string( templatePath ) ) &
               " doesn't exist or is not readable" );
        when MODE_ERROR =>
           err( "interal error: mode error on template " & optional_bold( to_string( templatePath ) ) );
        when END_ERROR =>
           err( "interal error: end of file reached on template " & optional_bold( to_string( templatePath ) ) );
        -- when others =>
       --  err( "unable to open template " & optional_bold( to_string( templatePath ) ) );
        end;
     end if;
  end if;

  -- Apply the return error status

  if error_found and last_status = 0 then
     last_status := 192;
  end if;
  Set_Exit_Status( Exit_Status( last_status ) );

end checkAndInterpretScript;

------------------------------------------------------------------------------
-- INTERPRET
--
-- Begin executing things.  Specifically, set up the environmental flags based
-- on the command line options, run the .profile script(s) and then interpret
-- commands or start an interactive session.  After the script is run and
-- templates have been specified, run the templates.  If a script has been
-- marked as depreciated, show the appropriate warning.
------------------------------------------------------------------------------

procedure interpret is
begin
  if optionOffset = 0 then                       -- no arguments or '-'?
     if isLoginShell then                        -- login shell? find profile
        doGlobalProfile;
        doLocalProfile;
     end if;
     inputMode := interactive;                          -- we're interactive
     if traceOpt then                                   -- -x / --trace?
        trace := true;                                  -- turn on trace
     end if;
     interactiveSession;                                -- start the session
  else
     checkAndInterpretScript( Argument( OptionOffset ) );
  end if;

  -- Apply the return error status

  if error_found and last_status = 0 then
     last_status := 192;
  end if;
  Set_Exit_Status( Exit_Status( last_status ) );

end interpret;

------------------------------------------------------------------------------
-- Housekeeping
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- START PARSER
--
-- Startup this package, performing any set up tasks.  In this case, set up
-- standard input, standard output and standard error so they can be redirected.
-- Also, initialize the random number generator.
--
-- The original stdin/out/err must be copied to prevent them from being
-- closed and lost.  They are needed at the shell prompt to draw the
-- prompt and to read typing by the user.  For output redirection in
-- scripts or commands, we'll always work with duplicates of the
-- originals, leaving the originals open for the shell prompt.
--
-- When copied, these are probably fd 3,4,5, but will record what dup
-- returns to be safe.  For example, if fd 0 is closed (by dup2) the file
-- actually will remain open until fd 3 is also closed.
--
-- currentStandardInput/Output/Error represent the file stdin/out/err has
-- been redirected to by Set_Input/Output/Error.  If none, the value is
-- 0,1,2 respectively.
--
-- The standard files standard_input, standard_output and standard_error
-- represent the original stdin/out/err...ie the copied fd 4,5,6.
------------------------------------------------------------------------------

procedure startParser is
begin
  originalStandardInput := dup( stdin );              -- record stdin
  originalStandardOutput := dup( stdout );            -- record stdout
  originalStandardError := dup( stderr );             -- record stderr
  currentStandardInput := originalStandardInput;      -- no redirection, stdin
  currentStandardOutput := originalStandardOutput;    -- no redirection, stdout
  currentStandardError := originalStandardError;      -- no redirection, stderr

  SetStandardVariables;                               -- built-in elaboration
  Ada.Numerics.Float_Random.Reset( random_generator );-- reset RND generator
  clearCommandHash;                                   -- initialize cmd table
end startParser;


------------------------------------------------------------------------------
-- SHUTDOWN PARSER
--
-- Shut down this package, performing any cleanup tasks.  In this case, none.
------------------------------------------------------------------------------

procedure shutdownParser is
begin
  null;
end shutdownParser;

end parser;
