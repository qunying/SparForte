#!/usr/local/bin/spar

procedure audio is

pragma annotate( summary, "audio [-l] file..." )
       @( description, "play audio files" )
       @( description, "Translated from a shell script by Heiner Steven" )
       @( see_also, "http://www.shelldorado.com/scripts/cmds/audio.txt" )
       @( author, "Ken O. Burtch" );
pragma license( unrestricted );

sound_path : constant string := "/usr/share/doc/packages/sox/";
pragma unchecked_import( shell, sound_path );
devdsp     : constant string := "/dev/dsp";
devaudio   : constant string := "/dev/audio";
played     : boolean := false;

procedure usage is
begin
  put( "usage: " ) @ (source_info.file);
  put_line ( "[-l] file...") @ ( "play audio files" );
  command_line.set_exit_status( 1 );
end usage;

begin

  if $# = 0 then
    usage;
    return;
  end if;

  for i in 1..command_line.argument_count loop
      if command_line.argument(i) = "-h" or
         command_line.argument(i) = "--help" then
         usage;
         return;
      elsif command_line.argument(i) = "-l" or
         command_line.argument(i) = "--list" then
         ls -C "$sound_path";
      else
         declare
           sound_file : constant string := sound_path &
             command_line.argument(i);
         begin
           if files.is_readable_file( sound_file ) then
              -- audio exists? try to play sound if an .au file
              if files.is_writable( devaudio ) then
                 if strings.tail( sound_file, 3 ) = ".au" then
                    cat "$sound_file" >> "$devaudio";
                    played;
                 end if;
              end if;
              -- dsp exists? try to play sound with wavplay
              if not played and files.is_writable( devdsp ) then
                 sound.play( sound_file );
                 played;
              end if;
           else
              put_line( standard_error, source_info.source_location & ": sound file doesn't exist or isn't readable" );
           end if;
         end;
      end if;
  end loop;
end audio;

-- VIM editor formatting instructions
-- vim: ft=spar
