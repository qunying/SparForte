#!/usr/local/bin/spar

pragma annotate( summary, "doors" );
pragma annotate( description, "Problem: You have 100 doors in a row that are all initially closed. You" );
pragma annotate( description, "make 100 passes by the doors. The first time through, you visit every door" );
pragma annotate( description, "and toggle the door (if the door is closed, you open it; if it is open, you" );
pragma annotate( description, "close it). The second time you only visit every 2nd door (door #2, #4, #6," );
pragma annotate( description, "...). The third time, every 3rd door (door #3, #6, #9, ...), etc, until you" );
pragma annotate( description, "only visit the 100th door." );
pragma annotate( description, "Question: What state are the doors in after the last pass? Which are open," );
pragma annotate( description, "which are closed?" );
pragma annotate( see_also, "http://rosettacode.org/wiki/100_doors" );
pragma annotate( author, "Ken O. Burtch" );
pragma license( unrestricted );

pragma restriction( no_external_commands );

procedure Doors is
   type Door_State is (Closed, Open);
   type Door_List is array(1..100) of Door_State;
   The_Doors : Door_List;
begin
   for I in 1..100 loop
      The_Doors(I) := Closed;
   end loop;
   for I in 1..100 loop
      for J in arrays.first(The_Doors)..arrays.last(The_Doors) loop
         if J mod I = 0 then
            if The_Doors(J) = Closed then
                The_Doors(J) := Open;
            else
               The_Doors(J) := Closed;
            end if;
         end if;
      end loop;
   end loop;
   for I in arrays.first(The_Doors)..arrays.last(The_Doors) loop
      put (I) @ (" is ") @ (The_Doors(I));
      new_line;
   end loop;
end Doors;

-- VIM editor formatting instructions
-- vim: ft=spar

