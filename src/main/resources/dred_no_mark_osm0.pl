/*
rules based on 
https://github.com/mrupp-sudo/gps-osm-project/blob/main/src/main/resources/datalog_rules.pl

*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	loop/0, read_stream/0, apply_one/0, phase/1, 
	available_input/1, extract_input/2,
	query/2, update/2, updt/3, stream_end/0,
	pending_fact/3,  derived_fact/2,
	next_query_id/1, current_query/1, create_query/1, 
	clean/0, applied_rules/2, print/0,
	node/3, nodeTag/5, way/3, wayTag/5,
	nextInWay/5, roadSegment/5, position/3,
	isReachable/3, roadConnection/5,
	yieldSign/3, stopSign/3, trafficSignal/3, pedestrianCrossing/3,
	tramCrossing/3, trainCrossing/3, intermodalStation/3, busStation/3,
	tramStation/3,  kindergarten/3, school/3.

:- chr_option(debug, off).
:- chr_option(optimize, off).


% initialization
init(Port) <=> 
	setup_call_cleanup(
		% connect to server 
		tcp_connect(Port, Stream, []),		
		(	stream(Stream),		
			% IDs for queries
			% ID 0 may be used for already present facts
			current_query(1),
			next_query_id(1),
			% start processing loop
			phase(0),
			loop,
			% indicate end of procesing
			writeln(Stream,"end"),
			flush_output(Stream),
			print
		),
		close(Stream)
	).		



% -- statistical information --
% count number of rule applications for each phase
applied_rules(N,P), applied_rules(M,P) <=>
	K is N + M,
	applied_rules(K,P).
	
% print out collected statistics
print, applied_rules(N,P) ==> writeln(applied_rules(N,P)).


% remove facts for simpler output
clean \ stream(_) <=> true.
clean \ phase(_) <=> true.		
clean \ next_query_id(_) <=> true.	
clean \ current_query(_) <=> true.	
clean \ node(_,_,_) <=> true.
clean \ nodeTag(_,_,_,_,_) <=> true.
clean \ way(_,_,_) <=> true.
clean \ wayTag(_,_,_,_,_) <=> true.
clean \ nextInWay(_,_,_,_,_) <=> true.
clean \ roadSegment(_,_,_,_,_) <=> true.
clean \ position(_,_,_) <=> true.
clean \ isReachable(_,_,_) <=> true.
clean \ roadConnection(_,_,_,_,_) <=> true.
clean \ yieldSign(_,_,_) <=> true.
clean \ stopSign(_,_,_) <=> true.
clean \ trafficSignal(_,_,_) <=> true.
clean \ pedestrianCrossing(_,_,_) <=> true.
clean \ tramCrossing(_,_,_) <=> true.
clean \ trainCrossing(_,_,_) <=> true.
clean \ intermodalStation(_,_,_) <=> true.
clean\ busStation(_,_,_) <=> true.
clean\ tramStation(_,_,_) <=> true.
clean \ kindergarten(_,_,_) <=> true.
clean \ school(_,_,_) <=> true.		


%----------
% -- termination --
	% prevent new query at end of stream
stream_end\ create_query(_) <=> true.
	% prevent waiting for next input
stream_end \ read_stream <=> true.
	% stop loop when all updates are fully processed
stream_end, apply_one, loop <=> true.


% remove changes that cancel each other
pending_fact(F,add,Q), pending_fact(F,del,Q) <=> true.

% new del-fact replaces old add-fact
node(X,del,Qd) \ node(X,add,Qa) <=> Qd > Qa | true.
nodeTag(X,Y,Z,del,Qd) \ nodeTag(X,Y,Z,add,Qa) <=> Qd > Qa | true.
way(X,del,Qd) \ way(X,add,Qa) <=> Qd > Qa | true.
wayTag(X,Y,Z,del,Qd) \ wayTag(X,Y,Z,add,Qa) <=> Qd > Qa | true.
nextInWay(X,Y,Z,del,Qd) \ nextInWay(X,Y,Z,add,Qa) <=> Qd > Qa | true.
roadSegment(X,Y,Z,del,Qd) \ roadSegment(X,Y,Z,add,Qa) <=> Qd > Qa | true.
position(X,del,Qd) \ position(X,add,Qa) <=> Qd > Qa | true.
isReachable(X,del,Qd) \ isReachable(X,add,Qa) <=> Qd > Qa | true.
roadConnection(X,Y,Z,del,Qd) \ roadConnection(X,Y,Z,add,Qa) <=> Qd > Qa | true.
yieldSign(X,del,Qd) \ yieldSign(X,add,Qa) <=> Qd > Qa | true.
stopSign(X,del,Qd) \ stopSign(X,add,Qa) <=> Qd > Qa | true.
trafficSignal(X,del,Qd) \ trafficSignal(X,add,Qa) <=> Qd > Qa | true.
pedestrianCrossing(X,del,Qd) \ pedestrianCrossing(X,add,Qa) <=> Qd > Qa | true.
tramCrossing(X,del,Qd) \ tramCrossing(X,add,Qa) <=> Qd > Qa | true.
trainCrossing(X,del,Qd) \ trainCrossing(X,add,Qa) <=> Qd > Qa | true.
intermodalStation(X,del,Qd) \ intermodalStation(X,add,Qa) <=> Qd > Qa | true.
busStation(X,del,Qd) \ busStation(X,add,Qa) <=> Qd > Qa | true.
tramStation(X,del,Qd) \ tramStation(X,add,Qa) <=> Qd > Qa | true.
kindergarten(X,del,Qd) \ kindergarten(X,add,Qa) <=> Qd > Qa | true.
school(X,del,Qd) \ school(X,add,Qa) <=> Qd > Qa | true.


% prevent duplicates
node(X,_,_) \ node(X,_,_) <=> true.
nodeTag(X,Y,Z,_,_) \ nodeTag(X,Y,Z,_,_) <=> true.
way(X,_,_) \ way(X,_,_) <=> true.
wayTag(X,Y,Z,_,_) \ wayTag(X,Y,Z,_,_) <=> true.
nextInWay(X,Y,Z,_,_) \ nextInWay(X,Y,Z,_,_) <=> true.
roadSegment(X,Y,Z,_,_) \ roadSegment(X,Y,Z,_,_) <=> true.
position(X,_,_) \ position(X,_,_) <=> true.
isReachable(X,_,_) \ isReachable(X,_,_) <=> true.
roadConnection(X,Y,Z,_,_) \ roadConnection(X,Y,Z,_,_) <=> true.
yieldSign(X,_,_) \ yieldSign(X,_,_) <=> true.
stopSign(X,_,_) \ stopSign(X,_,_) <=> true.
trafficSignal(X,_,_) \ trafficSignal(X,_,_) <=> true.
pedestrianCrossing(X,_,_) \ pedestrianCrossing(X,_,_) <=> true.
tramCrossing(X,_,_) \ tramCrossing(X,_,_) <=> true.
trainCrossing(X,_,_) \ trainCrossing(X,_,_) <=> true.
intermodalStation(X,_,_) \ intermodalStation(X,_,_) <=> true.
busStation(X,_,_) \ busStation(X,_,_) <=> true.
tramStation(X,_,_) \ tramStation(X,_,_) <=> true.
kindergarten(X,_,_) \ kindergarten(X,_,_) <=> true.
school(X,_,_) \ school(X,_,_) <=> true.


% only one rule application per iteration
apply_one \ apply_one <=> true.	


% do not read from stream when a query already available	
query(_,_) \ read_stream <=> true.	
	
	
% -- loop --	
% try to read input from stream, then apply one operation and repeat
loop <=> read_stream, apply_one, loop.	
		

%-------------------------------------------------	
% -- read input from stream --

% try to get next input from stream
stream(S) \ read_stream <=> 
	wait_for_input([S],L,0.001),
	available_input(L).
	
% no input from stream available
available_input([]) <=> true.	

% get input from stream
available_input([S]) <=>
	% read added and deleted facts from stream
	read_line_to_string(S,A),
	read_line_to_string(S,D),	
	extract_input(A,D),
	% insert query asking for every fact
	create_query(_Q).


%----------
% -- input is a query --
create_query(Q), next_query_id(N) <=>
	M is N + 1,
	next_query_id(M),
	query(Q,N).
	
	
% if no other query, insert delete-facts of current query
query(_,Q), current_query(Q) \ pending_fact([node,X],del,Q) <=>
	node(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([nodeTag,X,Y,Z],del,Q) <=>
	nodeTag(X,Y,Z,del,Q).
query(_,Q), current_query(Q) \ pending_fact([way,X],del,Q) <=>	
	way(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([wayTag,X,Y,Z],del,Q) <=>	
	wayTag(X,Y,Z,del,Q).
query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],del,Q) <=>
	nextInWay(X,Y,Z,del,Q).
query(_,Q), current_query(Q) \ pending_fact([roadSegment,X,Y,Z],del,Q) <=>	
	roadSegment(X,Y,Z,del,Q).
query(_,Q), current_query(Q) \ pending_fact([position,X],del,Q) <=>	
	position(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([isReachable,X],del,Q) <=>	
	isReachable(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([roadConnection,X,Y,Z],del,Q) <=>	
	roadConnection(X,Y,Z,del,Q).
query(_,Q), current_query(Q) \ pending_fact([yieldSign,X],del,Q) <=>	
	yieldSign(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([stopSign,X],del,Q) <=>	
	stopSign(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([trafficSignal,X],del,Q) <=>	
	trafficSignal(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([pedestrianCrossing,X],del,Q) <=>	
	pedestrianCrossing(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([tramCrossing,X],del,Q) <=>	
	tramCrossing(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([trainCrossing,X],del,Q) <=>	
	trainCrossing(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([intermodalStation,X],del,Q) <=>	
	intermodalStation(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([busStation,X],del,Q) <=>	
	busStation(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([tramStation,X],del,Q) <=>	
	tramStation(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([kindergarten,X],del,Q) <=>	
	kindergarten(X,del,Q).
query(_,Q), current_query(Q) \ pending_fact([school,X],del,Q) <=>	
	school(X,del,Q).	



%----------	
% -- input indicates end of stream --
extract_input("[]","[]") <=>	
	stream_end.

%----------	
% -- input is an update --
extract_input(X,Y) <=>	
	term_string(A,X),  
	term_string(D,Y),
	update(A,D).	

% get facts from update with appropriate add/del-operator
next_query_id(Q) \ update(Add,Del) <=> 
	updt(del,Del,Q),
	updt(add,Add,Q).

% prepare later insertion of facts
updt(_,[],_) <=> true.
updt(O,[F|Fs],Q) <=>
	pending_fact(F,O,Q), 
	updt(O,Fs,Q).	



%-------------------------------------------------
% -- overdeletion phase --
% pass deletion on to derived facts

	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
phase(0), current_query(Q),
node(X1,O1,Q1), node(X2,O2,Q2),
nextInWay(X1,X2,Y,O3,Q3), way(Y,O4,Q4),
wayTag(Y,"highway",T,O5,Q5) 
\ apply_one, roadSegment(X1,X2,Y,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3],[O4,Q4],[O5,Q5]]),
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	roadSegment(X1,X2,Y,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), position(X) --> isReachable(X)
phase(0), current_query(Q),
node(X,O1,Q1), position(X,O2,Q2) \ apply_one, isReachable(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	isReachable(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
phase(0), current_query(Q),
position(X1,O1,Q1), roadSegment(X1,X2,_,O2,Q2) \ apply_one, isReachable(X2,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	isReachable(X2,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
phase(0), current_query(Q),
isReachable(X1,O1,Q1), isReachable(X2,O2,Q2), roadConnection(X1,X2,X3,O3,Q3)
 \ apply_one, isReachable(X3,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	isReachable(X3,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
phase(0), current_query(Q),
roadSegment(X1,X2,_,O1,Q1), roadSegment(X2,X3,_,O2,Q2) \ apply_one, roadConnection(X1,X2,X3,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	roadConnection(X1,X2,X3,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	
	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"highway","give_way",O2,Q2) \ apply_one, yieldSign(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	yieldSign(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).	

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"highway","stop",O2,Q2) \ apply_one, stopSign(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	stopSign(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"highway","traffic_signals",O2,Q2) \ apply_one, trafficSignal(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	trafficSignal(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"highway","crossing",O2,Q2) \ apply_one, pedestrianCrossing(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |

	pedestrianCrossing(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"railway","tram_level_crossing",O2,Q2) \ apply_one, tramCrossing(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	tramCrossing(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"railway","level_crossing",O2,Q2) \ apply_one, trainCrossing(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	trainCrossing(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"public_transport","stop_position",O2,Q2), 
nodeTag(X,"bus","yes",O3,Q3), nodeTag(X,"tram","yes",O4,Q4) 
\ apply_one, intermodalStation(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3],[O4,Q4]]) |
	intermodalStation(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"public_transport","stop_position",O2,Q2), nodeTag(X,"bus","yes",O3,Q3) 
\ apply_one, busStation(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	busStation(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"public_transport","stop_position",O2,Q2), nodeTag(X,"tram","yes",O3,Q3) 
\ apply_one, tramStation(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	tramStation(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"amenity","kindergarten",O2,Q2) \ apply_one, kindergarten(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	kindergarten(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(0), current_query(Q),
way(X,O1,Q1), wayTag(X,"amenity","kindergarten",O2,Q2) \ apply_one, kindergarten(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	kindergarten(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(0), current_query(Q),
node(X,O1,Q1), nodeTag(X,"amenity","school",O2,Q2) \ apply_one, school(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	school(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(0), current_query(Q),
way(X,O1,Q1), wayTag(X,"amenity","school",O2,Q2) \ apply_one, school(X,add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	school(X,del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	


%----------	
% -- rederivation phase --	
% look for a rule instance that can still derive a deleted fact
	
	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
phase(1), 
node(X1,add,Q), node(X2,add,_),
nextInWay(X1,X2,Y,add,_), way(Y,add,_),
wayTag(Y,"highway",T,add,_) 
\ apply_one, roadSegment(X1,X2,Y,del,_) <=> 
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	roadSegment(X1,X2,Y,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), position(X) --> isReachable(X)
phase(1), 
node(X,add,Q), position(X,add,_) \ apply_one, isReachable(X,del,_) <=> 
	isReachable(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
phase(1), 
position(X1,add,Q), roadSegment(X1,X2,_,add,_) \ apply_one, isReachable(X2,del,_) <=> 
	isReachable(X2,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
phase(1), 
isReachable(X1,add,Q), isReachable(X2,add,_), roadConnection(X1,X2,X3,add,_)
 \ apply_one, isReachable(X3,del,_) <=> 
	isReachable(X3,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
phase(1), 
roadSegment(X1,X2,_,add,Q), roadSegment(X2,X3,_,add,_) \ apply_one, roadConnection(X1,X2,X3,del,_) <=> 
	roadConnection(X1,X2,X3,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	

	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(1), 
node(X,add,Q), nodeTag(X,"highway","give_way",add,_) \ apply_one, yieldSign(X,del,_) <=> 
	yieldSign(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).	

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(1),
node(X,add,Q), nodeTag(X,"highway","stop",add,_) \ apply_one, stopSign(X,del,_) <=> 
	stopSign(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(1),
node(X,add,Q), nodeTag(X,"highway","traffic_signals",add,_) \ apply_one, trafficSignal(X,del,_) <=> 
	trafficSignal(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(1),
node(X,add,Q), nodeTag(X,"highway","crossing",add,_) \ apply_one, pedestrianCrossing(X,del,_) <=> 
	pedestrianCrossing(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(1),
node(X,add,Q), nodeTag(X,"railway","tram_level_crossing",add,_) \ apply_one, tramCrossing(X,del,_) <=> 
	tramCrossing(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(1),
node(X,add,Q), nodeTag(X,"railway","level_crossing",add,_) \ apply_one, trainCrossing(X,del,_) <=> 
	trainCrossing(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(1),
node(X,add,Q), nodeTag(X,"public_transport","stop_position",add,_), 
nodeTag(X,"bus","yes",add,_), nodeTag(X,"tram","yes",add,_) 
\ apply_one, intermodalStation(X,del,_) <=> 
	intermodalStation(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(1),
node(X,add,Q), nodeTag(X,"public_transport","stop_position",add,_), nodeTag(X,"bus","yes",add,_) 
\ apply_one, busStation(X,del,_) <=> 
	busStation(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(1),
node(X,add,Q), nodeTag(X,"public_transport","stop_position",add,_), nodeTag(X,"tram","yes",add,_) 
\ apply_one, tramStation(X,del,_) <=> 
	tramStation(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(1),
node(X,add,Q), nodeTag(X,"amenity","kindergarten",add,_) \ apply_one, kindergarten(X,del,_) <=> 
	kindergarten(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(1),
way(X,add,Q), wayTag(X,"amenity","kindergarten",add,_) \ apply_one, kindergarten(X,del,_) <=> 
	kindergarten(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(1),
node(X,add,Q), nodeTag(X,"amenity","school",add,_) \ apply_one, school(X,del,_) <=> 
	school(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(1),
way(X,add,Q), wayTag(X,"amenity","school",add,_) \ apply_one, school(X,del,_) <=> 
	school(X,add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	


% - apply deletions
phase(2) \ node(_,del,_) <=> true.
phase(2) \ nodeTag(_,_,_,del,_) <=> true.
phase(2) \ way(_,del,_) <=> true.
phase(2) \ wayTag(_,_,_,del,_) <=> true.
phase(2) \ nextInWay(_,_,_,del,_) <=> true.
phase(2) \ roadSegment(_,_,_,del,_) <=> true.
phase(2) \ position(_,del,_) <=> true.
phase(2) \ isReachable(_,del,_) <=> true.
phase(2) \ roadConnection(_,_,_,del,_) <=> true.
phase(2) \ yieldSign(_,del,_) <=> true.
phase(2) \ stopSign(_,del,_) <=> true.
phase(2) \ trafficSignal(_,del,_) <=> true.
phase(2) \ pedestrianCrossing(_,del,_) <=> true.
phase(2) \ tramCrossing(_,del,_) <=> true.
phase(2) \ trainCrossing(_,del,_) <=> true.
phase(2) \ intermodalStation(_,del,_) <=> true.
phase(2) \ busStation(_,del,_) <=> true.
phase(2) \ tramStation(_,del,_) <=> true.
phase(2) \ kindergarten(_,del,_) <=> true.
phase(2) \ school(_,del,_) <=> true.

% insert remaining pending facts of current query
phase(2), query(_,Q), current_query(Q) \ pending_fact([node,X],add,Q) <=>
	node(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([nodeTag,X,Y,Z],add,Q) <=>
	nodeTag(X,Y,Z,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([way,X],add,Q) <=>	
	way(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([wayTag,X,Y,Z],add,Q) <=>	
	wayTag(X,Y,Z,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],add,Q) <=>
	nextInWay(X,Y,Z,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([roadSegment,X,Y,Z],add,Q) <=>	
	roadSegment(X,Y,Z,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([position,X],add,Q) <=>	
	position(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([isReachable,X],add,Q) <=>	
	isReachable(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([roadConnection,X,Y,Z],add,Q) <=>	
	roadConnection(X,Y,Z,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([yieldSign,X],add,Q) <=>	
	yieldSign(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([stopSign,X],add,Q) <=>	
	stopSign(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([trafficSignal,X],add,Q) <=>	
	trafficSignal(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([pedestrianCrossing,X],add,Q) <=>	
	pedestrianCrossing(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([tramCrossing,X],add,Q) <=>	
	tramCrossing(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([trainCrossing,X],add,Q) <=>	
	trainCrossing(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([intermodalStation,X],add,Q) <=>	
	intermodalStation(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([busStation,X],add,Q) <=>	
	busStation(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([tramStation,X],add,Q) <=>	
	tramStation(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([kindergarten,X],add,Q) <=>	
	kindergarten(X,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([school,X],add,Q) <=>	
	school(X,add,Q).			
	


%----------	
% -- insertion phase --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */

% do not apply rule if derived fact alread present
node(X,add,_) \ derived_fact([node,X],_) <=> true.	
nodeTag(X,Y,Z,add,_) \ derived_fact([nodeTag,X,Y,Z],_) <=> true.	
way(X,add,_) \ derived_fact([way,X],_) <=> true.	
wayTag(X,Y,Z,add,_) \ derived_fact([wayTag,X,Y,Z],_) <=> true.	
nextInWay(X,Y,Z,add,_) \ derived_fact([nextInWay,X,Y,Z],_) <=> true.	
roadSegment(X,Y,Z,add,_) \ derived_fact([roadSegment,X,Y,Z],_) <=> true.	
position(X,add,_) \ derived_fact([position,X],_) <=> true.	
isReachable(X,add,_) \ derived_fact([isReachable,X],_) <=> true.	
roadConnection(X,Y,Z,add,_) \ derived_fact([roadConnection,X,Y,Z],_) <=> true.	
yieldSign(X,add,_) \ derived_fact([yieldSign,X],_) <=> true.	
stopSign(X,add,_) \ derived_fact([stopSign,X],_) <=> true.	
trafficSignal(X,add,_) \ derived_fact([trafficSignal,X],_) <=> true.	
pedestrianCrossing(X,add,_) \ derived_fact([pedestrianCrossing,X],_) <=> true.	
tramCrossing(X,add,_) \ derived_fact([tramCrossing,X],_) <=> true.	
trainCrossing(X,add,_) \ derived_fact([trainCrossing,X],_) <=> true.	
intermodalStation(X,add,_) \ derived_fact([intermodalStation,X],_) <=> true.	
busStation(X,add,_) \ derived_fact([busStation,X],_) <=> true.	
tramStation(X,add,_) \ derived_fact([tramStation,X],_) <=> true.	
kindergarten(X,add,_) \ derived_fact([kindergarten,X],_) <=> true.	
school(X,add,_) \ derived_fact([school,X],_) <=> true.	



	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
phase(3), current_query(Q),
node(X1,add,Q1), node(X2,add,Q2), nextInWay(X1,X2,Y,add,Q3), way(Y,add,Q4),
wayTag(Y,"highway",T,add,Q5) ==>
	member(Q,[Q1,Q2,Q3,Q4,Q5]),
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	derived_fact([roadSegment,X1,X2,Y],Q).
	
	% node(X), position(X) --> isReachable(X)
phase(3), current_query(Q),
node(X,add,Q1), position(X,add,Q2) ==>
	member(Q, [Q1, Q2]) | 
	derived_fact([isReachable,X],Q).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
phase(3), current_query(Q),
position(X1,add,Q1), roadSegment(X1,X2,_,add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([isReachable,X2],Q).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
phase(3), current_query(Q),
isReachable(X1,add,Q1), isReachable(X2,add,Q2), roadConnection(X1,X2,X3,add,_) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([isReachable,X3],Q).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
phase(3), current_query(Q),
roadSegment(X1,X2,_,add,Q1), roadSegment(X2,X3,_,add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([roadConnection,X1,X2,X3],Q).
	

	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"highway","give_way",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([yieldSign,X],Q).

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"highway","stop",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([stopSign,X],Q).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"highway","traffic_signals",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([trafficSignal,X],Q).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"highway","crossing",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([pedestrianCrossing,X],Q).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"railway","tram_level_crossing",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([tramCrossing,X],Q).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"railway","level_crossing",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([trainCrossing,X],Q).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"public_transport","stop_position",add,Q2), 
nodeTag(X,"bus","yes",add,Q3), nodeTag(X,"tram","yes",add,Q4) 
==>
	member(Q, [Q1, Q2, Q3, Q4]) | 
	derived_fact([intermodalStation,X],Q).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"public_transport","stop_position",add,Q2), nodeTag(X,"bus","yes",add,Q3) 
==>
	member(Q, [Q1, Q2, Q3]) |
	derived_fact([busStation,X],Q).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"public_transport","stop_position",add,Q2), nodeTag(X,"tram","yes",add,Q3) 
==>
	member(Q, [Q1, Q2, Q3]) |
	derived_fact([tramStation,X],Q).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"amenity","kindergarten",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([kindergarten,X],Q).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(3), current_query(Q),
way(X,add,Q1), wayTag(X,"amenity","kindergarten",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([kindergarten,X],Q).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(3), current_query(Q),
node(X,add,Q1), nodeTag(X,"amenity","school",add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([school,X],Q).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(3), current_query(Q),
way(X,add,Q1), wayTag(X,"amenity","school",add,Q2)==>
	member(Q, [Q1, Q2]) |
	derived_fact([school,X],Q).
		

% insert derived head facts
apply_one, derived_fact([node,X],Q) <=> 	
	node(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([nodeTag,X,Y,Z],Q) <=> 	
	nodeTag(X,Y,Z,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([way,X],Q) <=> 
	way(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([wayTag,X,Y,Z],Q) <=> 	
	wayTag(X,Y,Z,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([nextInWay,X,Y,Z],Q) <=> 	
	nextInWay(X,Y,Z,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([roadSegment,X,Y,Z],Q) <=> 	
	roadSegment(X,Y,Z,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([position,X],Q) <=> 	
	position(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([isReachable,X],Q) <=> 	
	isReachable(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([roadConnection,X,Y,Z],Q) <=> 	
	roadConnection(X,Y,Z,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([yieldSign,X],Q) <=> 	
	yieldSign(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([stopSign,X],Q) <=> 	
	stopSign(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([trafficSignal,X],Q) <=> 	
	trafficSignal(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([pedestrianCrossing,X],Q) <=> 	
	pedestrianCrossing(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([tramCrossing,X],Q) <=> 	
	tramCrossing(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([trainCrossing,X],Q) <=> 	
	trainCrossing(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([intermodalStation,X],Q) <=> 	
	intermodalStation(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([busStation,X],Q) <=> 	
	busStation(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([tramStation,X],Q) <=> 	
	tramStation(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([kindergarten,X],Q) <=> 	
	kindergarten(X,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([school,X],Q) <=> 	
	school(X,add,Q),
	applied_rules(1,ins).	
	


%-------------------------------------------------
% -- move to next phase if no operation applicable --
current_query(Q), query(_,Q) \ apply_one, phase(N) <=>
	N < 4 |
	M is N + 1,
	phase(M).

%----------	
% -- answer query --	
% write query answers as line in output stream
phase(4), current_query(N), query(Q,N), stream(S) ==> 
	writeln(S,query(Q,N)).
	
phase(4), current_query(N), query(Q,N), node(X,add,_), stream(S) ==> 
	unifiable(Q,[node,X],_) |
	writeln(S,[node,X]).
phase(4), current_query(N), query(Q,N), nodeTag(X,Y,Z,add,_), stream(S) ==> 
	unifiable(Q,[nodeTag,X,Y,Z],_) |
	writeln(S,[nodeTag,X,Y,Z]).
phase(4), current_query(N), query(Q,N), way(X,add,_), stream(S) ==> 
	unifiable(Q,[way,X],_) |
	writeln(S,[way,X]).
phase(4), current_query(N), query(Q,N), wayTag(X,Y,Z,add,_), stream(S) ==> 
	unifiable(Q,[wayTag,X,Y,Z],_) |
	writeln(S,[wayTag,X,Y,Z]).
phase(4), current_query(N), query(Q,N), nextInWay(X,Y,Z,add,_), stream(S) ==> 
	unifiable(Q,[nextInWay,X,Y,Z],_) |
	writeln(S,[nextInWay,X,Y,Z]).
phase(4), current_query(N), query(Q,N), roadConnection(X,Y,Z,add,_), stream(S) ==> 
	unifiable(Q,[roadConnection,X,Y,Z],_) |
	writeln(S,[roadConnection,X,Y,Z]).
phase(4), current_query(N), query(Q,N), roadSegment(X,Y,Z,add,_), stream(S) ==> 
	unifiable(Q,[roadSegment,X,Y,Z],_) |
	writeln(S,[roadSegment,X,Y,Z]).
phase(4), current_query(N), query(Q,N), position(X,add,_), stream(S) ==> 
	unifiable(Q,[position,X],_) |
	writeln(S,[position,X]).
phase(4), current_query(N), query(Q,N), isReachable(X,add,_), stream(S) ==> 
	unifiable(Q,[isReachable,X],_) |
	writeln(S,[isReachable,X]).
phase(4), current_query(N), query(Q,N), yieldSign(X,add,_), stream(S) ==> 
	unifiable(Q,[yieldSign,X],_) |
	writeln(S,[yieldSign,X]).
phase(4), current_query(N), query(Q,N), stopSign(X,add,_), stream(S) ==> 
	unifiable(Q,[stopSign,X],_) |
	writeln(S,[stopSign,X]).
phase(4), current_query(N), query(Q,N), trafficSignal(X,add,_), stream(S) ==> 
	unifiable(Q,[trafficSignal,X],_) |
	writeln(S,[trafficSignal,X]).
phase(4), current_query(N), query(Q,N), pedestrianCrossing(X,add,_), stream(S) ==> 
	unifiable(Q,[pedestrianCrossing,X],_) |
	writeln(S,[pedestrianCrossing,X]).
phase(4), current_query(N), query(Q,N), tramCrossing(X,add,_), stream(S) ==> 
	unifiable(Q,[tramCrossing,X],_) |
	writeln(S,[tramCrossing,X]).
phase(4), current_query(N), query(Q,N), trainCrossing(X,add,_), stream(S) ==> 
	unifiable(Q,[trainCrossing,X],_) |
	writeln(S,[trainCrossing,X]).
phase(4), current_query(N), query(Q,N), intermodalStation(X,add,_), stream(S) ==> 
	unifiable(Q,[intermodalStation,X],_) |
	writeln(S,[intermodalStation,X]).
phase(4), current_query(N), query(Q,N), busStation(X,add,_), stream(S) ==> 
	unifiable(Q,[busStation,X],_) |
	writeln(S,[busStation,X]).
phase(4), current_query(N), query(Q,N), tramStation(X,add,_), stream(S) ==> 
	unifiable(Q,[tramStation,X],_) |
	writeln(S,[tramStation,X]).
phase(4), current_query(N), query(Q,N), kindergarten(X,add,_), stream(S) ==> 
	unifiable(Q,[kindergarten,X],_) |
	writeln(S,[kindergarten,X]).
phase(4), current_query(N), query(Q,N), school(X,add,_), stream(S) ==> 
	unifiable(Q,[school,X],_) |
	writeln(S,[school,X]).
	
% mark end of answers in stream
phase(4), stream(S), current_query(N) \ query(_,N) <=> 
	writeln(S,""), 
	flush_output(S).

%----------	
% -- prepare next query --
	
% increase current and mark ID value and reset phase
phase(4), current_query(M) <=>
	N is M + 1,
	current_query(N),
	phase(0).

