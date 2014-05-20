#!/usr/local/bin/spar

pragma annotate( summary, "dateformat");
pragma annotate( description, "Display the current date in the formats of '2007-11-10' " );
pragma annotate( description, "and 'Sunday, November 10, 2007'." );
pragma annotate( see_also, "http://rosettacode.org/wiki/Date_format" );
pragma annotate( "Ken O. Burtch" );
pragma license( unrestricted );

pragma restriction( no_external_commands );

procedure dateformat is
   function Month_Image (Month : calendar.month_number) return string is
   begin
      case Month is
         when 1  => return "January";
         when 2  => return "February";
         when 3  => return "March";
         when 4  => return "April";
         when 5  => return "May";
         when 6  => return "June";
         when 7  => return "July";
         when 8  => return "August";
         when 9  => return "September";
         when 10 => return "October";
         when 11 => return "November";
         when others => return "December";
      end case;
   end Month_Image;
   function Day_Image (Day : integer) return string is
   begin
      case Day is
         when 0 => return "Monday";
         when 1 => return "Tuesday";
         when 2 => return "Wednesday";
         when 3 => return "Thursday";
         when 4 => return "Friday";
         when 5 => return "Saturday";
         when others => return "Sunday";
      end case;
   end Day_Image;
   Today : calendar.time := calendar.clock;
begin
   --put_line(
   --Put_Line (Image (Today) (1..10));

   put( calendar.year( Today ), "9999" ) @( "-" )
     @( calendar.month( Today ), "99" ) @( "-" )
     @( calendar.day( Today ), "99" );
   new_line;

   put_line(
        Day_Image( calendar.day_of_week( Today ) ) & ", " &
        Month_Image( calendar.month( Today ) ) &
        strings.image( calendar.day( Today ) ) & "," &
        strings.image( calendar.year( Today ) ) );
end dateformat;

-- VIM editor formatting instructions
-- vim: ft=spar

