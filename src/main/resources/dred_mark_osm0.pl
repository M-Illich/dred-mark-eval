/*
DRed where changes of next query are introduced as marks

rules based on 
https://github.com/mrupp-sudo/gps-osm-project/blob/main/src/main/resources/datalog_rules.pl
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	loop/0, read_stream/0, apply_one/0, phase/1, 
	available_input/1, extract_input/2,
	query/2, update/2, updt/3, stream_end/0,
	pending_fact/3, derived_fact/3,
	next_query_id/1, current_query/1, mark_query/1, create_query/1,
	compute_positive_mark/2, compute_negative_mark/2,
	clean/0, applied_rules/2, marked_facts/2, marked_facts/3, print/0,
	node/4, nodeTag/6, way/4, wayTag/6,
	nextInWay/6, roadSegment/6, position/4,
	isReachable/4, roadConnection/6,
	yieldSign/4, stopSign/4, trafficSignal/4, pedestrianCrossing/4,
	tramCrossing/4, trainCrossing/4, intermodalStation/4, busStation/4,
	tramStation/4,  kindergarten/4, school/4.

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
			mark_query(2),
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
		

% count number of marked facts
marked_facts(N,O), marked_facts(M,O) <=>
	K is N + M,
	marked_facts(K,O).
	
% print out collected statistics
print, applied_rules(N,P) ==> writeln(applied_rules(N,P)).
print, marked_facts(N,O) ==> writeln(marked_facts(N,O)).


% remove constraints for simpler output
clean \ stream(_) <=> true.
clean \ phase(_) <=> true.		
clean \ next_query_id(_) <=> true.	
clean \ current_query(_) <=> true.			
clean \ mark_query(_) <=> true.		
clean \ node(_,_,_,_) <=> true.
clean \ nodeTag(_,_,_,_,_,_) <=> true.
clean \ way(_,_,_,_) <=> true.
clean \ wayTag(_,_,_,_,_,_) <=> true.
clean \ nextInWay(_,_,_,_,_,_) <=> true.
clean \ roadSegment(_,_,_,_,_,_) <=> true.
clean \ position(_,_,_,_) <=> true.
clean \ isReachable(_,_,_,_) <=> true.
clean \ roadConnection(_,_,_,_,_,_) <=> true.
clean \ yieldSign(_,_,_,_) <=> true.
clean \ stopSign(_,_,_,_) <=> true.
clean \ trafficSignal(_,_,_,_) <=> true.
clean \ pedestrianCrossing(_,_,_,_) <=> true.
clean \ tramCrossing(_,_,_,_) <=> true.
clean \ trainCrossing(_,_,_,_) <=> true.
clean \ intermodalStation(_,_,_,_) <=> true.
clean\ busStation(_,_,_,_) <=> true.
clean\ tramStation(_,_,_,_) <=> true.
clean \ kindergarten(_,_,_,_) <=> true.
clean \ school(_,_,_,_) <=> true.		



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
node(X,del,Qd,_) \ node(X,add,Qa,_) <=> Qd > Qa | true.
nodeTag(X,Y,Z,del,Qd,_) \ nodeTag(X,Y,Z,add,Qa,_) <=> Qd > Qa | true.
way(X,del,Qd,_) \ way(X,add,Qa,_) <=> Qd > Qa | true.
wayTag(X,Y,Z,del,Qd,_) \ wayTag(X,Y,Z,add,Qa,_) <=> Qd > Qa | true.
nextInWay(X,Y,Z,del,Qd,_) \ nextInWay(X,Y,Z,add,Qa,_) <=> Qd > Qa | true.
roadSegment(X,Y,Z,del,Qd,_) \ roadSegment(X,Y,Z,add,Qa,_) <=> Qd > Qa | true.
position(X,del,Qd,_) \ position(X,add,Qa,_) <=> Qd > Qa | true.
isReachable(X,del,Qd,_) \ isReachable(X,add,Qa,_) <=> Qd > Qa | true.
roadConnection(X,Y,Z,del,Qd,_) \ roadConnection(X,Y,Z,add,Qa,_) <=> Qd > Qa | true.
yieldSign(X,del,Qd,_) \ yieldSign(X,add,Qa,_) <=> Qd > Qa | true.
stopSign(X,del,Qd,_) \ stopSign(X,add,Qa,_) <=> Qd > Qa | true.
trafficSignal(X,del,Qd,_) \ trafficSignal(X,add,Qa,_) <=> Qd > Qa | true.
pedestrianCrossing(X,del,Qd,_) \ pedestrianCrossing(X,add,Qa,_) <=> Qd > Qa | true.
tramCrossing(X,del,Qd,_) \ tramCrossing(X,add,Qa,_) <=> Qd > Qa | true.
trainCrossing(X,del,Qd,_) \ trainCrossing(X,add,Qa,_) <=> Qd > Qa | true.
intermodalStation(X,del,Qd,_) \ intermodalStation(X,add,Qa,_) <=> Qd > Qa | true.
busStation(X,del,Qd,_) \ busStation(X,add,Qa,_) <=> Qd > Qa | true.
tramStation(X,del,Qd,_) \ tramStation(X,add,Qa,_) <=> Qd > Qa | true.
kindergarten(X,del,Qd,_) \ kindergarten(X,add,Qa,_) <=> Qd > Qa | true.
school(X,del,Qd,_) \ school(X,add,Qa,_) <=> Qd > Qa | true.


% prevent duplicates
node(X,_,_,_) \ node(X,_,_,_) <=> true.
nodeTag(X,Y,Z,_,_,_) \ nodeTag(X,Y,Z,_,_,_) <=> true.
way(X,_,_,_) \ way(X,_,_,_) <=> true.
wayTag(X,Y,Z,_,_,_) \ wayTag(X,Y,Z,_,_,_) <=> true.
nextInWay(X,Y,Z,_,_,_) \ nextInWay(X,Y,Z,_,_,_) <=> true.
roadSegment(X,Y,Z,_,_,_) \ roadSegment(X,Y,Z,_,_,_) <=> true.
position(X,_,_,_) \ position(X,_,_,_) <=> true.
isReachable(X,_,_,_) \ isReachable(X,_,_,_) <=> true.
roadConnection(X,Y,Z,_,_,_) \ roadConnection(X,Y,Z,_,_,_) <=> true.
yieldSign(X,_,_,_) \ yieldSign(X,_,_,_) <=> true.
stopSign(X,_,_,_) \ stopSign(X,_,_,_) <=> true.
trafficSignal(X,_,_,_) \ trafficSignal(X,_,_,_) <=> true.
pedestrianCrossing(X,_,_,_) \ pedestrianCrossing(X,_,_,_) <=> true.
tramCrossing(X,_,_,_) \ tramCrossing(X,_,_,_) <=> true.
trainCrossing(X,_,_,_) \ trainCrossing(X,_,_,_) <=> true.
intermodalStation(X,_,_,_) \ intermodalStation(X,_,_,_) <=> true.
busStation(X,_,_,_) \ busStation(X,_,_,_) <=> true.
tramStation(X,_,_,_) \ tramStation(X,_,_,_) <=> true.
kindergarten(X,_,_,_) \ kindergarten(X,_,_,_) <=> true.
school(X,_,_,_) \ school(X,_,_,_) <=> true.

% only one rule application per iteration
apply_one \ apply_one <=> true.	
	
	
% do not read from stream when already two queries given	
query(_,Q), mark_query(Q) \ read_stream <=> true.

% postpone updates until first one completed
query(_,1) \ read_stream <=> true.
	
	
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
	% variable at end allows mark if needed
query(_,Q), current_query(Q) \ pending_fact([node,X],del,Q) <=>
	node(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([nodeTag,X,Y,Z],del,Q) <=>
	nodeTag(X,Y,Z,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([way,X],del,Q) <=>	
	way(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([wayTag,X,Y,Z],del,Q) <=>	
	wayTag(X,Y,Z,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],del,Q) <=>
	nextInWay(X,Y,Z,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([roadSegment,X,Y,Z],del,Q) <=>	
	roadSegment(X,Y,Z,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([position,X],del,Q) <=>	
	position(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([isReachable,X],del,Q) <=>	
	isReachable(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([roadConnection,X,Y,Z],del,Q) <=>	
	roadConnection(X,Y,Z,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([yieldSign,X],del,Q) <=>	
	yieldSign(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([stopSign,X],del,Q) <=>	
	stopSign(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([trafficSignal,X],del,Q) <=>	
	trafficSignal(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([pedestrianCrossing,X],del,Q) <=>	
	pedestrianCrossing(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([tramCrossing,X],del,Q) <=>	
	tramCrossing(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([trainCrossing,X],del,Q) <=>	
	trainCrossing(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([intermodalStation,X],del,Q) <=>	
	intermodalStation(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([busStation,X],del,Q) <=>	
	busStation(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([tramStation,X],del,Q) <=>	
	tramStation(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([kindergarten,X],del,Q) <=>	
	kindergarten(X,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([school,X],del,Q) <=>	
	school(X,del,Q,_).	
	

	% new query is next one
% mark facts that are changed by next query by assigning value 1 to variable	
query(_,Q), mark_query(Q), node(X,O1,_,M) \ pending_fact([node,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.	
query(_,Q), mark_query(Q), nodeTag(X,Y,Z,O1,_,M) \ pending_fact([nodeTag,X,Y,Z],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), way(X,O1,_,M) \ pending_fact([way,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), wayTag(X,Y,Z,O1,_,M) \ pending_fact([wayTag,X,Y,Z],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), nextInWay(X,Y,Z,O1,_,M) \ pending_fact([nextInWay,X,Y,Z],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), roadSegment(X,Y,Z,O1,_,M) \ pending_fact([roadSegment,X,Y,Z],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), position(X,O1,_,M) \ pending_fact([position,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), isReachable(X,O1,_,M) \ pending_fact([isReachable,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), roadConnection(X,Y,Z,O1,_,M) \ pending_fact([roadConnection,X,Y,Z],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), yieldSign(X,O1,_,M) \ pending_fact([yieldSign,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), stopSign(X,O1,_,M) \ pending_fact([stopSign,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), trafficSignal(X,O1,_,M) \ pending_fact([trafficSignal,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), pedestrianCrossing(X,O1,_,M) \ pending_fact([pedestrianCrossing,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), tramCrossing(X,O1,_,M) \ pending_fact([tramCrossing,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), trainCrossing(X,O1,_,M) \ pending_fact([trainCrossing,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), intermodalStation(X,O1,_,M) \ pending_fact([intermodalStation,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), busStation(X,O1,_,M) \ pending_fact([busStation,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), tramStation(X,O1,_,M) \ pending_fact([tramStation,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), kindergarten(X,O1,_,M) \ pending_fact([kindergarten,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), school(X,O1,_,M) \ pending_fact([school,X],O2,Q) <=>
	O1 \== O2 |
	M = 1.
	


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
node(X1,O1,Q1,M1), node(X2,O2,Q2,M2),
nextInWay(X1,X2,Y,O3,Q3,M3), way(Y,O4,Q4,M4),
wayTag(Y,"highway",T,O5,Q5,M5) 
\ apply_one, roadSegment(X1,X2,Y,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3],[O4,Q4],[O5,Q5]]),
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	compute_positive_mark([(O1,M1,ex),(O2,M2,ex),(O3,M3,ex),(O4,M4,ex),(O5,M5,ex)],M),
	roadSegment(X1,X2,Y,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), position(X) --> isReachable(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), position(X,O2,Q2,M2) \ apply_one, isReachable(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	isReachable(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
phase(0), current_query(Q),
position(X1,O1,Q1,M1), roadSegment(X1,X2,_,O2,Q2,M2) \ apply_one, isReachable(X2,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,im)],M),
	isReachable(X2,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
phase(0), current_query(Q),
isReachable(X1,O1,Q1,M1), isReachable(X2,O2,Q2,M2), roadConnection(X1,X2,X3,O3,Q3,M3)
 \ apply_one, isReachable(X3,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	compute_positive_mark([(O1,M1,im),(O2,M2,im),(O3,M3,im)],M),
	isReachable(X3,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
phase(0), current_query(Q),
roadSegment(X1,X2,_,O1,Q1,M1), roadSegment(X2,X3,_,O2,Q2,M2) \ apply_one, roadConnection(X1,X2,X3,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,im), (O2,M2,im)],M),
	roadConnection(X1,X2,X3,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	
	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"highway","give_way",O2,Q2,M2) \ apply_one, yieldSign(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	yieldSign(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).	

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"highway","stop",O2,Q2,M2) \ apply_one, stopSign(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	stopSign(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"highway","traffic_signals",O2,Q2,M2) \ apply_one, trafficSignal(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	trafficSignal(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"highway","crossing",O2,Q2,M2) \ apply_one, pedestrianCrossing(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	pedestrianCrossing(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"railway","tram_level_crossing",O2,Q2,M2) \ apply_one, tramCrossing(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	tramCrossing(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"railway","level_crossing",O2,Q2,M2) \ apply_one, trainCrossing(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	trainCrossing(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"public_transport","stop_position",O2,Q2,M2), 
nodeTag(X,"bus","yes",O3,Q3,M3), nodeTag(X,"tram","yes",O4,Q4,M4) 
\ apply_one, intermodalStation(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3],[O4,Q4]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex), (O3,M3,ex), (O4,M4,ex)],M),
	intermodalStation(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"public_transport","stop_position",O2,Q2,M2), nodeTag(X,"bus","yes",O3,Q3,M3) 
\ apply_one, busStation(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex), (O3,M3,ex)],M),
	busStation(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"public_transport","stop_position",O2,Q2,M2), nodeTag(X,"tram","yes",O3,Q3,M3) 
\ apply_one, tramStation(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex), (O3,M3,ex)],M),
	tramStation(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"amenity","kindergarten",O2,Q2,M2) \ apply_one, kindergarten(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	kindergarten(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(0), current_query(Q),
way(X,O1,Q1,M1), wayTag(X,"amenity","kindergarten",O2,Q2,M2) \ apply_one, kindergarten(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	kindergarten(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(0), current_query(Q),
node(X,O1,Q1,M1), nodeTag(X,"amenity","school",O2,Q2,M2) \ apply_one, school(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	school(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(0), current_query(Q),
way(X,O1,Q1,M1), wayTag(X,"amenity","school",O2,Q2,M2) \ apply_one, school(X,add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,ex)],M),
	school(X,del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	
% - compute positive mark -
/* idea: remove constraint if conditions not met,
	if constraint remains with empty list, 
	then conditions satisfied and mark set to 1*/ 
compute_positive_mark([],M) <=> M = 1.
	% requirements not satisfied --> no mark
compute_positive_mark([(del,M,ex)|_],_) <=> var(M) | true.
compute_positive_mark([(add,1,_)|_],_) <=> true.
compute_positive_mark([(_,M,im)|_],_) <=> var(M) | true.
	% requirements hold so far --> consider next elements
compute_positive_mark([_|L],M) <=> compute_positive_mark(L,M).	



%----------	
% -- rederivation phase --	
% look for a rule instance that can still derive a deleted fact

	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
phase(1), 
node(X1,add,Q,M1), node(X2,add,_,M2),
nextInWay(X1,X2,Y,add,_,M3), way(Y,add,_,M4),
wayTag(Y,"highway",T,add,_,M5) 
\ apply_one, roadSegment(X1,X2,Y,del,_,_) <=> 
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	compute_negative_mark([M1, M2, M3, M4, M5], M),
	roadSegment(X1,X2,Y,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), position(X) --> isReachable(X)
phase(1), 
node(X,add,Q,M1), position(X,add,_,M2) \ apply_one, isReachable(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	isReachable(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
phase(1), 
position(X1,add,Q,M1), roadSegment(X1,X2,_,add,_,M2) \ apply_one, isReachable(X2,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	isReachable(X2,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
phase(1), 
isReachable(X1,add,Q,M1), isReachable(X2,add,_,M2), roadConnection(X1,X2,X3,add,_,M3)
 \ apply_one, isReachable(X3,del,_,_) <=> 
	compute_negative_mark([M1, M2, M3], M),
	isReachable(X3,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
phase(1), 
roadSegment(X1,X2,_,add,Q,M1), roadSegment(X2,X3,_,add,_,M2) \ apply_one, roadConnection(X1,X2,X3,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	roadConnection(X1,X2,X3,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	

	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(1), 
node(X,add,Q,M1), nodeTag(X,"highway","give_way",add,_,M2) \ apply_one, yieldSign(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	yieldSign(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).	

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"highway","stop",add,_,M2) \ apply_one, stopSign(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	stopSign(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"highway","traffic_signals",add,_,M2) \ apply_one, trafficSignal(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	trafficSignal(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"highway","crossing",add,_,M2) \ apply_one, pedestrianCrossing(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	pedestrianCrossing(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"railway","tram_level_crossing",add,_,M2) \ apply_one, tramCrossing(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	tramCrossing(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"railway","level_crossing",add,_,M2) \ apply_one, trainCrossing(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	trainCrossing(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"public_transport","stop_position",add,_,M2), 
nodeTag(X,"bus","yes",add,_,M3), nodeTag(X,"tram","yes",add,_,M4) 
\ apply_one, intermodalStation(X,del,_,_) <=> 
	compute_negative_mark([M1, M2, M3, M4], M),
	intermodalStation(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"public_transport","stop_position",add,_,M2), nodeTag(X,"bus","yes",add,_,M3) 
\ apply_one, busStation(X,del,_,_) <=> 
	compute_negative_mark([M1, M2, M3], M),
	busStation(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"public_transport","stop_position",add,_,M2), nodeTag(X,"tram","yes",add,_,M3) 
\ apply_one, tramStation(X,del,_,_) <=> 
	compute_negative_mark([M1, M2, M3], M),
	tramStation(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"amenity","kindergarten",add,_,M2) \ apply_one, kindergarten(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	kindergarten(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(1),
way(X,add,Q,M1), wayTag(X,"amenity","kindergarten",add,_,M2) \ apply_one, kindergarten(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	kindergarten(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(1),
node(X,add,Q,M1), nodeTag(X,"amenity","school",add,_,M2) \ apply_one, school(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	school(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(1),
way(X,add,Q,M1), wayTag(X,"amenity","school",add,_,M2) \ apply_one, school(X,del,_,_) <=> 
	compute_negative_mark([M1, M2], M),
	school(X,add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).



% - compute negative mark -
/* at least one element in list has to be 1*/
compute_negative_mark([],_) <=> true.
compute_negative_mark([1|_],M) <=> M = 1.
compute_negative_mark([_|L],M) <=> compute_negative_mark(L,M).


% - apply deletions and new insertions
% keep marked del-facts for next query and remove rest
phase(2), mark_query(Q) \ node(X,del,_,1) <=>
	pending_fact([node,X],add,Q),
	marked_facts(1,delEx).
phase(2), mark_query(Q) \ nodeTag(X,Y,Z,del,_,1) <=>
	pending_fact([nodeTag,X,Y,Z],add,Q),
	marked_facts(1,delEx).	
phase(2), mark_query(Q) \ way(X,del,_,1) <=>	
	pending_fact([way,X],add,Q),
	marked_facts(1,delEx).
phase(2), mark_query(Q) \ wayTag(X,Y,Z,del,_,1) <=>	
	pending_fact([wayTag,X,Y,Z],add,Q),
	marked_facts(1,delEx).
phase(2), mark_query(Q) \ nextInWay(X,Y,Z,del,_,1) <=>
	pending_fact([nextInWay,X,Y,Z],add,Q),
	marked_facts(1,delEx).
phase(2), mark_query(Q) \ roadSegment(X,Y,Z,del,_,1) <=>	
	pending_fact([roadSegment,X,Y,Z],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ position(X,del,_,1) <=>	
	pending_fact([position,X],add,Q),
	marked_facts(1,delEx).
phase(2), mark_query(Q) \ isReachable(X,del,_,1) <=>	
	pending_fact([isReachable,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ roadConnection(X,Y,Z,del,_,1) <=>	
	pending_fact([roadConnection,X,Y,Z],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ yieldSign(X,del,_,1) <=>	
	pending_fact([yieldSign,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ stopSign(X,del,_,1) <=>	
	pending_fact([stopSign,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ trafficSignal(X,del,_,1) <=>	
	pending_fact([trafficSignal,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ pedestrianCrossing(X,del,_,1) <=>	
	pending_fact([pedestrianCrossing,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ tramCrossing(X,del,_,1) <=>	
	pending_fact([tramCrossing,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ trainCrossing(X,del,_,1) <=>	
	pending_fact([trainCrossing,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ intermodalStation(X,del,_,1) <=>	
	pending_fact([intermodalStation,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ busStation(X,del,_,1) <=>	
	pending_fact([busStation,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ tramStation(X,del,_,1) <=>	
	pending_fact([tramStation,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ kindergarten(X,del,_,1) <=>	
	pending_fact([kindergarten,X],add,Q),
	marked_facts(1,delIm).
phase(2), mark_query(Q) \ school(X,del,_,1) <=>	
	pending_fact([school,X],add,Q),
	marked_facts(1,delIm).
	
	
% remove non-marked facts
phase(2) \ node(_,del,_,M) <=> var(M) | true.
phase(2) \ nodeTag(_,_,_,del,_,M) <=> var(M) | true.
phase(2) \ way(_,del,_,M) <=> var(M) | true.
phase(2) \ wayTag(_,_,_,del,_,M) <=> var(M) | true.
phase(2) \ nextInWay(_,_,_,del,_,M) <=> var(M) | true.
phase(2) \ roadSegment(_,_,_,del,_,M) <=> var(M) | true.
phase(2) \ position(_,del,_,M) <=> var(M) | true.
phase(2) \ isReachable(_,del,_,M) <=> var(M) | true.
phase(2) \ roadConnection(_,_,_,del,_,M) <=> var(M) | true.
phase(2) \ yieldSign(_,del,_,M) <=> var(M) | true.
phase(2) \ stopSign(_,del,_,M) <=> var(M) | true.
phase(2) \ trafficSignal(_,del,_,M) <=> var(M) | true.
phase(2) \ pedestrianCrossing(_,del,_,M) <=> var(M) | true.
phase(2) \ tramCrossing(_,del,_,M) <=> var(M) | true.
phase(2) \ trainCrossing(_,del,_,M) <=> var(M) | true.
phase(2) \ intermodalStation(_,del,_,M) <=> var(M) | true.
phase(2)\ busStation(_,del,_,M) <=> var(M) | true.
phase(2)\ tramStation(_,del,_,M) <=> var(M) | true.
phase(2) \ kindergarten(_,del,_,M) <=> var(M) | true.
phase(2) \ school(_,del,_,M) <=> var(M) | true.	


% insert remaining pending facts of current query
phase(2), query(_,Q), current_query(Q) \ pending_fact([node,X],add,Q) <=>
	node(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([nodeTag,X,Y,Z],add,Q) <=>
	nodeTag(X,Y,Z,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([way,X],add,Q) <=>	
	way(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([wayTag,X,Y,Z],add,Q) <=>	
	wayTag(X,Y,Z,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],add,Q) <=>
	nextInWay(X,Y,Z,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([roadSegment,X,Y,Z],add,Q) <=>	
	roadSegment(X,Y,Z,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([position,X],add,Q) <=>	
	position(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([isReachable,X],add,Q) <=>	
	isReachable(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([roadConnection,X,Y,Z],add,Q) <=>	
	roadConnection(X,Y,Z,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([yieldSign,X],add,Q) <=>	
	yieldSign(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([stopSign,X],add,Q) <=>	
	stopSign(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([trafficSignal,X],add,Q) <=>	
	trafficSignal(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([pedestrianCrossing,X],add,Q) <=>	
	pedestrianCrossing(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([tramCrossing,X],add,Q) <=>	
	tramCrossing(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([trainCrossing,X],add,Q) <=>	
	trainCrossing(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([intermodalStation,X],add,Q) <=>	
	intermodalStation(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([busStation,X],add,Q) <=>	
	busStation(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([tramStation,X],add,Q) <=>	
	tramStation(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([kindergarten,X],add,Q) <=>	
	kindergarten(X,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([school,X],add,Q) <=>	
	school(X,add,Q,_).		
	
	


%----------	
% -- insertion phase --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */
	
% do not apply rule if derived fact alread present
node(X,add,_,_) \ derived_fact([node,X],_,_) <=> true.	
nodeTag(X,Y,Z,add,_,_) \ derived_fact([nodeTag,X,Y,Z],_,_) <=> true.	
way(X,add,_,_) \ derived_fact([way,X],_,_) <=> true.	
wayTag(X,Y,Z,add,_,_) \ derived_fact([wayTag,X,Y,Z],_,_) <=> true.	
nextInWay(X,Y,Z,add,_,_) \ derived_fact([nextInWay,X,Y,Z],_,_) <=> true.	
roadSegment(X,Y,Z,add,_,_) \ derived_fact([roadSegment,X,Y,Z],_,_) <=> true.	
position(X,add,_,_) \ derived_fact([position,X],_,_) <=> true.	
isReachable(X,add,_,_) \ derived_fact([isReachable,X],_,_) <=> true.	
roadConnection(X,Y,Z,add,_,_) \ derived_fact([roadConnection,X,Y,Z],_,_) <=> true.	
yieldSign(X,add,_,_) \ derived_fact([yieldSign,X],_,_) <=> true.	
stopSign(X,add,_,_) \ derived_fact([stopSign,X],_,_) <=> true.	
trafficSignal(X,add,_,_) \ derived_fact([trafficSignal,X],_,_) <=> true.	
pedestrianCrossing(X,add,_,_) \ derived_fact([pedestrianCrossing,X],_,_) <=> true.	
tramCrossing(X,add,_,_) \ derived_fact([tramCrossing,X],_,_) <=> true.	
trainCrossing(X,add,_,_) \ derived_fact([trainCrossing,X],_,_) <=> true.	
intermodalStation(X,add,_,_) \ derived_fact([intermodalStation,X],_,_) <=> true.	
busStation(X,add,_,_) \ derived_fact([busStation,X],_,_) <=> true.	
tramStation(X,add,_,_) \ derived_fact([tramStation,X],_,_) <=> true.	
kindergarten(X,add,_,_) \ derived_fact([kindergarten,X],_,_) <=> true.	
school(X,add,_,_) \ derived_fact([school,X],_,_) <=> true.	


	% node(X1), node(X2), nextInWay(X1, X2, Y), way(Y), wayTag(Y, "highway", T), 
	% member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	
	% --> roadSegment(X1, X2, Y)
phase(3), current_query(Q),
node(X1,add,Q1,M1), node(X2,add,Q2,M2),
nextInWay(X1,X2,Y,add,Q3,M3), way(Y,add,Q4,M4),
wayTag(Y,"highway",T,add,Q5,M5) ==>
	member(Q,[Q1,Q2,Q3,Q4,Q5]),
	member(T, ["motorway","trunk","primary","secondary","tertiary","unclassified","residential","motorway_link","trunk_link","primary_link","secondary_link","tertiary_link","living_street","service"])	|
	compute_negative_mark([M1, M2, M3, M4, M5], M),
	derived_fact([roadSegment,X1,X2,Y],Q,M).
	
	% node(X), position(X) --> isReachable(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), position(X,add,Q2,M2) ==>
	member(Q, [Q1, Q2]) | 
	compute_negative_mark([M1, M2], M),
	derived_fact([isReachable,X],Q,M).
	
	% position(X1), roadSegment(X1, X2, _) --> isReachable(X2)
phase(3), current_query(Q),
position(X1,add,Q1,M1), roadSegment(X1,X2,_,add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([isReachable,X2],Q,M).

	% isReachable(X1), isReachable(X2), roadConnection(X1, X2, X3) --> isReachable(X3)
phase(3), current_query(Q),
isReachable(X1,add,Q1,M1), isReachable(X2,add,Q2,M2), roadConnection(X1,X2,X3,add,_,M3) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2, M3], M),
	derived_fact([isReachable,X3],Q,M).

	% roadSegment(X1, X2, _), roadSegment(X2, X3, _) --> roadConnection(X1, X2, X3)
phase(3), current_query(Q),
roadSegment(X1,X2,_,add,Q1,M1), roadSegment(X2,X3,_,add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([roadConnection,X1,X2,X3],Q,M).
	

	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"highway","give_way",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([yieldSign,X],Q,M).

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"highway","stop",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([stopSign,X],Q,M).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"highway","traffic_signals",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([trafficSignal,X],Q,M).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"highway","crossing",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([pedestrianCrossing,X],Q,M).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"railway","tram_level_crossing",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([tramCrossing,X],Q,M).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"railway","level_crossing",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([trainCrossing,X],Q,M).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"public_transport","stop_position",add,Q2,M2), 
nodeTag(X,"bus","yes",add,Q3,M3), nodeTag(X,"tram","yes",add,Q4,M4) 
==>
	member(Q, [Q1, Q2, Q3, Q4]) | 
	compute_negative_mark([M1, M2, M3, M4], M),
	derived_fact([intermodalStation,X],Q,M).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"public_transport","stop_position",add,Q2,M2), nodeTag(X,"bus","yes",add,Q3,M3) 
==>
	member(Q, [Q1, Q2, Q3]) |
	compute_negative_mark([M1, M2, M3], M),
	derived_fact([busStation,X],Q,M).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"public_transport","stop_position",add,Q2,M2), nodeTag(X,"tram","yes",add,Q3,M3) 
==>
	member(Q, [Q1, Q2, Q3]) |
	compute_negative_mark([M1, M2, M3], M),
	derived_fact([tramStation,X],Q,M).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"amenity","kindergarten",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([kindergarten,X],Q,M).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(3), current_query(Q),
way(X,add,Q1,M1), wayTag(X,"amenity","kindergarten",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([kindergarten,X],Q,M).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(3), current_query(Q),
node(X,add,Q1,M1), nodeTag(X,"amenity","school",add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([school,X],Q,M).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(3), current_query(Q),
way(X,add,Q1,M1), wayTag(X,"amenity","school",add,Q2,M2)==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([school,X],Q,M).


% insert derived head facts
apply_one, derived_fact([node,X],Q,M) <=> 	
	node(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([nodeTag,X,Y,Z],Q,M) <=> 	
	nodeTag(X,Y,Z,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([way,X],Q,M) <=> 
	way(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([wayTag,X,Y,Z],Q,M) <=> 	
	wayTag(X,Y,Z,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([nextInWay,X,Y,Z],Q,M) <=> 	
	nextInWay(X,Y,Z,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([roadSegment,X,Y,Z],Q,M) <=> 	
	roadSegment(X,Y,Z,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([position,X],Q,M) <=> 	
	position(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([isReachable,X],Q,M) <=> 	
	isReachable(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([roadConnection,X,Y,Z],Q,M) <=> 	
	roadConnection(X,Y,Z,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([yieldSign,X],Q,M) <=> 	
	yieldSign(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([stopSign,X],Q,M) <=> 	
	stopSign(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([trafficSignal,X],Q,M) <=> 	
	trafficSignal(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([pedestrianCrossing,X],Q,M) <=> 	
	pedestrianCrossing(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([tramCrossing,X],Q,M) <=> 	
	tramCrossing(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([trainCrossing,X],Q,M) <=> 	
	trainCrossing(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([intermodalStation,X],Q,M) <=> 	
	intermodalStation(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([busStation,X],Q,M) <=> 	
	busStation(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([tramStation,X],Q,M) <=> 	
	tramStation(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([kindergarten,X],Q,M) <=> 	
	kindergarten(X,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([school,X],Q,M) <=> 	
	school(X,add,Q,M),
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

phase(4), current_query(N), query(Q,N), node(X,add,_,_), stream(S) ==> 
	unifiable(Q,[node,X],_) |
	writeln(S,[node,X]).
phase(4), current_query(N), query(Q,N), nodeTag(X,Y,Z,add,_,_), stream(S) ==> 
	unifiable(Q,[nodeTag,X,Y,Z],_) |
	writeln(S,[nodeTag,X,Y,Z]).
phase(4), current_query(N), query(Q,N), way(X,add,_,_), stream(S) ==> 
	unifiable(Q,[way,X],_) |
	writeln(S,[way,X]).
phase(4), current_query(N), query(Q,N), wayTag(X,Y,Z,add,_,_), stream(S) ==> 
	unifiable(Q,[wayTag,X,Y,Z],_) |
	writeln(S,[wayTag,X,Y,Z]).
phase(4), current_query(N), query(Q,N), nextInWay(X,Y,Z,add,_,_), stream(S) ==> 
	unifiable(Q,[nextInWay,X,Y,Z],_) |
	writeln(S,[nextInWay,X,Y,Z]).
phase(4), current_query(N), query(Q,N), roadConnection(X,Y,Z,add,_,_), stream(S) ==> 
	unifiable(Q,[roadConnection,X,Y,Z],_) |
	writeln(S,[roadConnection,X,Y,Z]).
phase(4), current_query(N), query(Q,N), roadSegment(X,Y,Z,add,_,_), stream(S) ==> 
	unifiable(Q,[roadSegment,X,Y,Z],_) |
	writeln(S,[roadSegment,X,Y,Z]).
phase(4), current_query(N), query(Q,N), position(X,add,_,_), stream(S) ==> 
	unifiable(Q,[position,X],_) |
	writeln(S,[position,X]).
phase(4), current_query(N), query(Q,N), isReachable(X,add,_,_), stream(S) ==> 
	unifiable(Q,[isReachable,X],_) |
	writeln(S,[isReachable,X]).
phase(4), current_query(N), query(Q,N), yieldSign(X,add,_,_), stream(S) ==> 
	unifiable(Q,[yieldSign,X],_) |
	writeln(S,[yieldSign,X]).
phase(4), current_query(N), query(Q,N), stopSign(X,add,_,_), stream(S) ==> 
	unifiable(Q,[stopSign,X],_) |
	writeln(S,[stopSign,X]).
phase(4), current_query(N), query(Q,N), trafficSignal(X,add,_,_), stream(S) ==> 
	unifiable(Q,[trafficSignal,X],_) |
	writeln(S,[trafficSignal,X]).
phase(4), current_query(N), query(Q,N), pedestrianCrossing(X,add,_,_), stream(S) ==> 
	unifiable(Q,[pedestrianCrossing,X],_) |
	writeln(S,[pedestrianCrossing,X]).
phase(4), current_query(N), query(Q,N), tramCrossing(X,add,_,_), stream(S) ==> 
	unifiable(Q,[tramCrossing,X],_) |
	writeln(S,[tramCrossing,X]).
phase(4), current_query(N), query(Q,N), trainCrossing(X,add,_,_), stream(S) ==> 
	unifiable(Q,[trainCrossing,X],_) |
	writeln(S,[trainCrossing,X]).
phase(4), current_query(N), query(Q,N), intermodalStation(X,add,_,_), stream(S) ==> 
	unifiable(Q,[intermodalStation,X],_) |
	writeln(S,[intermodalStation,X]).
phase(4), current_query(N), query(Q,N), busStation(X,add,_,_), stream(S) ==> 
	unifiable(Q,[busStation,X],_) |
	writeln(S,[busStation,X]).
phase(4), current_query(N), query(Q,N), tramStation(X,add,_,_), stream(S) ==> 
	unifiable(Q,[tramStation,X],_) |
	writeln(S,[tramStation,X]).
phase(4), current_query(N), query(Q,N), kindergarten(X,add,_,_), stream(S) ==> 
	unifiable(Q,[kindergarten,X],_) |
	writeln(S,[kindergarten,X]).
phase(4), current_query(N), query(Q,N), school(X,add,_,_), stream(S) ==> 
	unifiable(Q,[school,X],_) |
	writeln(S,[school,X]).
	
% mark end of answers in stream
phase(4), stream(S), current_query(N) \ query(_,N) <=> 
	writeln(S,""), 
	flush_output(S).

%----------	
% -- prepare next query --

% transform marked add-facts into del-facts for next query
phase(4), mark_query(Q) \ node(X,add,_,1) <=>
	node(X,del,Q,_),
	marked_facts(1,addEx).
phase(4), mark_query(Q) \ nodeTag(X,Y,Z,add,_,1) <=>
	nodeTag(X,Y,Z,del,Q,_),
	marked_facts(1,addEx).	
phase(4), mark_query(Q) \ way(X,add,_,1) <=>	
	way(X,del,Q,_),
	marked_facts(1,addEx).
phase(4), mark_query(Q) \ wayTag(X,Y,Z,add,_,1) <=>	
	wayTag(X,Y,Z,del,Q,_),
	marked_facts(1,addEx).
phase(4), mark_query(Q) \ nextInWay(X,Y,Z,add,_,1) <=>
	nextInWay(X,Y,Z,del,Q,_),
	marked_facts(1,addEx).
phase(4), mark_query(Q) \ roadSegment(X,Y,Z,add,_,1) <=>	
	roadSegment(X,Y,Z,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ position(X,add,_,1) <=>	
	position(X,del,Q,_),
	marked_facts(1,addEx).
phase(4), mark_query(Q) \ isReachable(X,add,_,1) <=>	
	isReachable(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ roadConnection(X,Y,Z,add,_,1) <=>	
	roadConnection(X,Y,Z,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ yieldSign(X,add,_,1) <=>	
	yieldSign(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ stopSign(X,add,_,1) <=>	
	stopSign(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ trafficSignal(X,add,_,1) <=>	
	trafficSignal(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ pedestrianCrossing(X,add,_,1) <=>	
	pedestrianCrossing(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ tramCrossing(X,add,_,1) <=>	
	tramCrossing(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ trainCrossing(X,add,_,1) <=>	
	trainCrossing(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ intermodalStation(X,add,_,1) <=>	
	intermodalStation(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ busStation(X,add,_,1) <=>	
	busStation(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ tramStation(X,add,_,1) <=>	
	tramStation(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ kindergarten(X,add,_,1) <=>	
	kindergarten(X,del,Q,_),
	marked_facts(1,addIm).
phase(4), mark_query(Q) \ school(X,add,_,1) <=>	
	school(X,del,Q,_),
	marked_facts(1,addIm).	
	
	
% increase current and mark ID value and reset phase
phase(4), current_query(_), mark_query(M) <=>
	N is M + 1,
	mark_query(N),
	current_query(M),
	phase(0).
