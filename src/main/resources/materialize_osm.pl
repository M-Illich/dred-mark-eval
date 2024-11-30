/*
read facts rom stream and compute materialization
	i.e., exhaustivel apply rules until no further facts can be derived
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	available_input/1, extract_input/1,
	fact/1, end/0.

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


% get facts from input
extract_input([]) <=> true.
extract_input([X|Xs]) <=>
	fact(X),
	extract_input(Xs).
	

% remove duplicates
fact(X) \ fact(X) <=> true.	
		

%-------------------------------------------------	
% -- compute materialization --
	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
fact([node,X1]), fact([node,X2]),
fact([nextInWay,X1,X2,Y]), fact([way,Y]),
fact([wayTag,Y,"highway",T]) ==>
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	fact([roadSegment,X1,X2,Y]).
	
	% node(X), position(X) --> isReachable(X)
fact([node,X]), fact([position,X]) ==>
	fact([isReachable,X]).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
fact([position,X1]), fact([roadSegment,X1,X2,_]) ==>
	fact([isReachable,X2]).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
fact([isReachable,X1]), fact([isReachable,X2]), fact([roadConnection,X1,X2,X3]) ==>
	fact([isReachable,X3]).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
fact([roadSegment,X1,X2,_]), fact([roadSegment,X2,X3,_]) ==>
	fact([roadConnection,X1,X2,X3]).


	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
fact([node,X]), fact([nodeTag,X,"highway","give_way"]) ==>
	fact([yieldSign,X]).

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
fact([node,X]), fact([nodeTag,X,"highway","stop"]) ==>
	fact([stopSign,X]).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
fact([node,X]), fact([nodeTag,X,"highway","traffic_signals"]) ==>
	fact([trafficSignal,X]).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
fact([node,X]), fact([nodeTag,X,"highway","crossing"])  ==>
	fact([pedestrianCrossing,X]).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
fact([node,X]), fact([nodeTag,X,"railway","tram_level_crossing"]) ==>
	fact([tramCrossing,X]).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
fact([node,X]), fact([nodeTag,X,"railway","level_crossing"]) ==>
	fact([trainCrossing,X]).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
fact([node,X]), fact([nodeTag,X,"public_transport","stop_position"]), 
fact([nodeTag,X,"bus","yes"]), fact([nodeTag,X,"tram","yes"]) ==>
	fact([intermodalStation,X]).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
fact([node,X]), fact([nodeTag,X,"public_transport","stop_position"]), fact([nodeTag,X,"bus","yes"]) ==>
	fact([busStation,X]).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
fact([node,X]), fact([nodeTag,X,"public_transport","stop_position"]), fact([nodeTag,X,"tram","yes"]) ==>
	fact([tramStation,X]).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
fact([node,X]), fact([nodeTag,X,"amenity","kindergarten"]) ==>
	fact([kindergarten,X]).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
fact([way,X]), fact([wayTag,X,"amenity","kindergarten"]) ==>
	fact([kindergarten,X]).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
fact([node,X]), fact([nodeTag,X,"amenity","school"]) ==>
	fact([school,X]).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
fact([way,X]), fact([wayTag,X,"amenity","school"]) ==>
	fact([school,X]).	




%-------------------------------------------------	
% -- write all facts to stream --
fact(F), stream(S) ==> 
	writeln(S,F).
% mark end of answers in stream
stream(S), end <=> 
	writeln(S,""), 
	flush_output(S).


