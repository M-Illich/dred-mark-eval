/*
read facts rom stream and compute materialization
	i.e., exhaustivel apply rules until no further facts can be derived
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	available_input/1, extract_input/1, end/0,
	node/1, nodeTag/3, way/1, wayTag/3,
	nextInWay/3, roadSegment/3, position/1,
	isReachable/1, roadConnection/3,
	yieldSign/1, stopSign/1, trafficSignal/1, pedestrianCrossing/1,
	tramCrossing/1, trainCrossing/1, intermodalStation/1, busStation/1,
	tramStation/1,  kindergarten/1, school/1,
	count/1,
	relation/1, relationTag/3, relationMember/4, mandatoryDirection/3.

:- chr_option(debug, off).
:- chr_option(optimize, off).


% initialization
init(Port) <=> 
	setup_call_cleanup(
		% connect to server 
		tcp_connect(Port, Stream, []),		
		(	stream(Stream),	
			% indicate end of procesing
			end,
			writeln(Stream,"end"),
			flush_output(Stream)
		),
		close(Stream)
	).		
		

%-------------------------------------------------	
% -- read input from stream --

% get input from stream
stream(S) ==> 
	wait_for_input([S],L,infinite),
	available_input(L).

% get input from stream
available_input([S]) <=>
	% read from stream
	read_line_to_string(S,L), 
	term_string(T,L),
	extract_input(T).
	
	% -- TODO --
extract_input(_) ==> count(1).
count(X), count(Y) <=> Z is X + Y, count(Z).	
	

% get facts from input
extract_input([]) <=> true.	
extract_input([[relation,X]|Xs]) <=>	
	relation(X),
	extract_input(Xs).
extract_input([[relationTag,X,Y,Z]|Xs]) <=>	
	relationTag(X,Y,Z),
	extract_input(Xs).
extract_input([[relationMember,X,Y,Z,W]|Xs]) <=>	
	relationMember(X,Y,Z,W),
	extract_input(Xs).
extract_input([[node,X]|Xs]) <=>	
	node(X),
	extract_input(Xs).
extract_input([[nodeTag,X,Y,Z]|Xs]) <=>	
	nodeTag(X,Y,Z),
	extract_input(Xs).
extract_input([[way,X]|Xs]) <=>
	way(X),
	extract_input(Xs).
extract_input([[wayTag,X,Y,Z]|Xs]) <=>
	wayTag(X,Y,Z),
	extract_input(Xs).
extract_input([[nextInWay,X,Y,Z]|Xs]) <=>
	nextInWay(X,Y,Z),
	extract_input(Xs).
extract_input([[roadSegment,X,Y,Z]|Xs]) <=>
	roadSegment(X,Y,Z),
	extract_input(Xs).
extract_input([[position,X]|Xs]) <=>
	position(X),
	extract_input(Xs).
extract_input([[isReachable,X]|Xs]) <=>
	isReachable(X),
	extract_input(Xs).
extract_input([[roadConnection,X,Y,Z]|Xs]) <=>
	roadConnection(X,Y,Z),
	extract_input(Xs).
extract_input([[yieldSign,X]|Xs]) <=>
	yieldSign(X),
	extract_input(Xs).
extract_input([[stopSign,X]|Xs]) <=>
	stopSign(X),
	extract_input(Xs).
extract_input([[trafficSignal,X]|Xs]) <=>
	trafficSignal(X),
	extract_input(Xs).
extract_input([[pedestrianCrossing,X]|Xs]) <=>
	pedestrianCrossing(X),
	extract_input(Xs).
extract_input([[tramCrossing,X]|Xs]) <=>
	tramCrossing(X),
	extract_input(Xs).
extract_input([[trainCrossing,X]|Xs]) <=>
	trainCrossing(X),
	extract_input(Xs).
extract_input([[intermodalStation,X]|Xs]) <=>
	intermodalStation(X),
	extract_input(Xs).
extract_input([[busStation,X]|Xs]) <=>
	busStation(X),
	extract_input(Xs).
extract_input([[tramStation,X]|Xs]) <=>
	tramStation(X),
	extract_input(Xs).
extract_input([[kindergarten,X]|Xs]) <=>
	kindergarten(X),
	extract_input(Xs).
extract_input([[school,X]|Xs]) <=>
	school(X),
	extract_input(Xs).
% exclude irrelevant fats
extract_input([_|Xs]) <=>
	extract_input(Xs).	
	

% remove duplicates
relation(X) \ node(X) <=> true.
relationTag(X,Y,Z) \ relationTag(X,Y,Z) <=> true.
relationMember(X,Y,Z,W) \ relationMember(X,Y,Z,W) <=> true.
mandatoryDirection(X,Y,Z) \ mandatoryDirection(X,Y,Z) <=> true.
node(X) \ node(X) <=> true.
nodeTag(X,Y,Z) \ nodeTag(X,Y,Z) <=> true.
way(X) \ way(X) <=> true.
wayTag(X,Y,Z) \ wayTag(X,Y,Z) <=> true.
nextInWay(X,Y,Z) \ nextInWay(X,Y,Z) <=> true.
roadSegment(X,Y,Z) \ roadSegment(X,Y,Z) <=> true.
position(X) \ position(X) <=> true.
isReachable(X) \ isReachable(X) <=> true.
roadConnection(X,Y,Z) \ roadConnection(X,Y,Z) <=> true.
yieldSign(X) \ yieldSign(X) <=> true.
stopSign(X) \ stopSign(X) <=> true.
trafficSignal(X) \ trafficSignal(X) <=> true.
pedestrianCrossing(X) \ pedestrianCrossing(X) <=> true.
tramCrossing(X) \ tramCrossing(X) <=> true.
trainCrossing(X) \ trainCrossing(X) <=> true.
intermodalStation(X) \ intermodalStation(X) <=> true.
busStation(X) \ busStation(X) <=> true.
tramStation(X) \ tramStation(X) <=> true.
kindergarten(X) \ kindergarten(X) <=> true.
school(X) \ school(X) <=> true.
		

%-------------------------------------------------	
% -- compute materialization --
	% mandatoryDirection(X1, X2, X3) --> roadConnection(X1, X2, X3)
mandatoryDirection(X1, X2, X3) ==> roadConnection(X1, X2, X3).
	
	% relation(R), relationTag(R, "restriction", T),
	% relationMember(Y1, "way", "from", R), relationMember(X2, "node", "via", R),
	% relationMember(Y2, "way", "to", R), roadSegment(X1, X2, Y1), roadSegment(X2, X3, Y2),
	% member(T, ["only_straight_on","only_left_turn","only_right_turn"])
	% --> mandatoryDirection(X1, X2, X3)	
relation(R), relationTag(R, "restriction", T),
relationMember(Y1, "way", "from", R), relationMember(X2, "node", "via", R),
relationMember(Y2, "way", "to", R), roadSegment(X1, X2, Y1), roadSegment(X2, X3, Y2) ==>
	member(T, ["only_straight_on","only_left_turn","only_right_turn"]) |
	mandatoryDirection(X1, X2, X3).

	% relation(R), relationTag(R, "restriction", T),
	% relationMember(Y1, "way", "via", R), relationMember(Y2, "way", "to", R), 
	% roadSegment(X1, X2, Y1), roadSegment(X2, X3, Y2),
	% member(T, ["only_straight_on","only_left_turn","only_right_turn"])
	% --> mandatoryDirection(X1, X2, X3)	
relation(R), relationTag(R, "restriction", T),
relationMember(Y1, "way", "via", R), relationMember(Y2, "way", "to", R), 
roadSegment(X1, X2, Y1), roadSegment(X2, X3, Y2) ==>
	member(T, ["only_straight_on","only_left_turn","only_right_turn"]) |
	mandatoryDirection(X1, X2, X3).


	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
node(X1), node(X2),
nextInWay(X1,X2,Y), way(Y),
wayTag(Y,"highway",T) ==>
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	roadSegment(X1,X2,Y).
	
	% node(X), position(X) --> isReachable(X)
node(X), position(X) ==>
	isReachable(X).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
position(X1), roadSegment(X1,X2,_) ==>
	isReachable(X2).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
isReachable(X1), isReachable(X2), roadConnection(X1,X2,X3) ==>
	isReachable(X3).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
roadSegment(X1,X2,_), roadSegment(X2,X3,_) ==>
	roadConnection(X1,X2,X3).


	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
node(X), nodeTag(X,"highway","give_way") ==>
	yieldSign(X).

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
node(X), nodeTag(X,"highway","stop") ==>
	stopSign(X).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
node(X), nodeTag(X,"highway","traffic_signals") ==>
	trafficSignal(X).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
node(X), nodeTag(X,"highway","crossing")  ==>
	pedestrianCrossing(X).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
node(X), nodeTag(X,"railway","tram_level_crossing") ==>
	tramCrossing(X).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
node(X), nodeTag(X,"railway","level_crossing") ==>
	trainCrossing(X).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
node(X), nodeTag(X,"public_transport","stop_position"), 
nodeTag(X,"bus","yes"), nodeTag(X,"tram","yes") ==>
	intermodalStation(X).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") ==>
	busStation(X).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") ==>
	tramStation(X).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
node(X), nodeTag(X,"amenity","kindergarten") ==>
	kindergarten(X).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
way(X), wayTag(X,"amenity","kindergarten") ==>
	kindergarten(X).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
node(X), nodeTag(X,"amenity","school") ==>
	school(X).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
way(X), wayTag(X,"amenity","school") ==>
	school(X).	



%-------------------------------------------------	
% -- write all facts to stream --
relation(X), stream(S) ==> 	
	writeln(S,[relation,X]).
relationTag(X,Y,Z), stream(S) ==> 
	writeln(S,[relationTag,X,Y,Z]).
relationMember(X,Y,Z,W), stream(S) ==> 
	writeln(S,[relationMember,X,Y,Z,W]).
mandatoryDirection(X,Y,Z), stream(S) ==> 
	writeln(S,[mandatoryDirection,X,Y,Z]).
node(X), stream(S) ==> 	
	writeln(S,[node,X]).
nodeTag(X,Y,Z), stream(S) ==> 
	writeln(S,[nodeTag,X,Y,Z]).
way(X), stream(S) ==> 
	writeln(S,[way,X]).
wayTag(X,Y,Z), stream(S) ==> 
	writeln(S,[wayTag,X,Y,Z]).
nextInWay(X,Y,Z), stream(S) ==> 
	writeln(S,[nextInWay,X,Y,Z]).
roadConnection(X,Y,Z), stream(S) ==> 
	writeln(S,[roadConnection,X,Y,Z]).
roadSegment(X,Y,Z), stream(S) ==> 
	writeln(S,[roadSegment,X,Y,Z]).
position(X), stream(S) ==> 
	writeln(S,[position,X]).
isReachable(X), stream(S) ==> 
	writeln(S,[isReachable,X]).
yieldSign(X), stream(S) ==> 
	writeln(S,[yieldSign,X]).
stopSign(X), stream(S) ==> 
	writeln(S,[stopSign,X]).
trafficSignal(X), stream(S) ==> 
	writeln(S,[trafficSignal,X]).
pedestrianCrossing(X), stream(S) ==> 
	writeln(S,[pedestrianCrossing,X]).
tramCrossing(X), stream(S) ==> 
	writeln(S,[tramCrossing,X]).
trainCrossing(X), stream(S) ==> 
	writeln(S,[trainCrossing,X]).
intermodalStation(X), stream(S) ==> 
	writeln(S,[intermodalStation,X]).
busStation(X), stream(S) ==> 
	writeln(S,[busStation,X]).
tramStation(X), stream(S) ==> 
	writeln(S,[tramStation,X]).
kindergarten(X), stream(S) ==> 
	writeln(S,[kindergarten,X]).
school(X), stream(S) ==> 
	writeln(S,[school,X]).
	
% mark end of answers in stream
stream(S), end <=> 
	writeln(S,""), 
	flush_output(S).


