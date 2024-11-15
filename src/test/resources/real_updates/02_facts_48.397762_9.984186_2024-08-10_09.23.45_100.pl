add(node(9)).
add(nodeTag(9, "public_transport", "stop_position")).
add(nodeTag(9, "bus", "yes")).
add(nodeTag(9, "tram", "yes")).
add(node(10)).
add(nodeTag(10, "amenity", "kindergarten")).
add(way(11)).
add(wayTag(11, "amenity", "kindergarten")).
delete(node(4)).
delete(nodeTag(4, "highway", "crossing")).
delete(node(5)).
delete(nodeTag(5, "highway", "tram_level_crossing")).
delete(node(6)).
delete(nodeTag(6, "highway", "level_crossing")).
