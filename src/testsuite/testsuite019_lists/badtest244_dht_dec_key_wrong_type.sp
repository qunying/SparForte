t : dynamic_hash_tables.table;
dynamic_hash_tables.new_table( t, integer );
dynamic_hash_tables.set( t, "counter", 0 );
dynamic_hash_tables.decrement( t, 1234 ); -- should be string

