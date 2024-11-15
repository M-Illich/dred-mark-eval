add(node(6)).
add(nodeTag(6, "highway", "level_crossing")).
add(node(7)).
add(nodeTag(7, "public_transport", "stop_position")).
add(nodeTag(7, "bus", "yes")).
add(node(8)).
add(nodeTag(8, "public_transport", "stop_position")).
add(nodeTag(8, "tram", "yes")).
delete(node(1)).
delete(nodeTag(1, "highway", "give_way")).
delete(node(2)).
delete(nodeTag(2, "highway", "stop")).
delete(node(3)).
delete(nodeTag(3, "highway", "traffic_signals")).
