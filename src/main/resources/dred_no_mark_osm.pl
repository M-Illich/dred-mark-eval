/*
rules based on 
https://github.com/mrupp-sudo/gps-osm-project/blob/main/src/main/resources/datalog_rules.pl

*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	loop/0, read_stream/0, apply_one/0, phase/1, 
	available_input/1, extract_input/2,
	query/2, update/2, updt/3, stream_end/0,
	pending_fact/3, fact/3, derived_fact/2,
	next_query_id/1, current_query/1, 
	clean/0, applied_rules/2, print/0.

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
clean \ fact(_,_,_) <=> true.	
clean \ stream(_) <=> true.
clean \ phase(_) <=> true.		
clean \ next_query_id(_) <=> true.	
clean \ current_query(_) <=> true.			


%----------
% -- termination --
	% prevent new query at end of stream
stream_end, query(_,_) \ query(_,_) <=> true.
	% prevent waiting for next input
stream_end \ read_stream <=> true.
	% stop loop when all updates are fully processed
stream_end, apply_one, loop <=> true.


% remove changes that cancel each other
pending_fact(F,add,Q), pending_fact(F,del,Q) <=> true.

% new del-fact replaces old add-fact
fact(F,del,Qd) \ fact(F,add,Qa) <=> Qd > Qa | true.

% prevent duplicates
fact(F,_,_) \ fact(F,_,_) <=> true.
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
available_input([S]), next_query_id(N) <=>
	% read added and deleted facts from stream
	read_line_to_string(S,A),
	read_line_to_string(S,D),	
	extract_input(A,D),
	% insert query asking for every fact
	M is N + 1,
	next_query_id(M),
	query(_Q,N).


%----------
% -- input is a query --
% if no other query, insert delete-facts of current query
query(_,Q), current_query(Q) \ pending_fact(F,del,Q) <=>
	% variable at end allows mark if needed
	fact(F,del,Q).



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

	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"highway","give_way"],O2,Q2) \ apply_one, fact([yieldSign,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([yieldSign,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).	

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"highway","stop"],O2,Q2) \ apply_one, fact([stopSign,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([stopSign,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"highway","traffic_signals"],O2,Q2) \ apply_one, fact([trafficSignal,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([trafficSignal,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"highway","crossing"],O2,Q2) \ apply_one, fact([pedestrianCrossing,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([pedestrianCrossing,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"railway","tram_level_crossing"],O2,Q2) \ apply_one, fact([tramCrossing,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([tramCrossing,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"railway","level_crossing"],O2,Q2) \ apply_one, fact([trainCrossing,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([trainCrossing,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"public_transport","stop_position"],O2,Q2), 
fact([nodeTag,X,"bus","yes"],O3,Q3), fact([nodeTag,X,"tram","yes"],O4,Q4) 
\ apply_one, fact([intermodalStation,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3],[O4,Q4]]) |
	fact([intermodalStation,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"public_transport","stop_position"],O2,Q2), fact([nodeTag,X,"bus","yes"],O3,Q3) 
\ apply_one, fact([busStation,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	fact([busStation,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"public_transport","stop_position"],O2,Q2), fact([nodeTag,X,"tram","yes"],O3,Q3) 
\ apply_one, fact([tramStation,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2],[O3,Q3]]) |
	fact([tramStation,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"amenity","kindergarten"],O2,Q2) \ apply_one, fact([kindergarten,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([kindergarten,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(0), current_query(Q),
fact([way,X],O1,Q1), fact([wayTag,X,"amenity","kindergarten"],O2,Q2) \ apply_one, fact([kindergarten,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([kindergarten,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(0), current_query(Q),
fact([node,X],O1,Q1), fact([nodeTag,X,"amenity","school"],O2,Q2) \ apply_one, fact([school,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([school,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(0), current_query(Q),
fact([way,X],O1,Q1), fact([wayTag,X,"amenity","school"],O2,Q2) \ apply_one, fact([school,X],add,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	fact([school,X],del,Q),
	% enable counting of applied rules per phase
	applied_rules(1,del).
	


%----------	
% -- rederivation phase --	
% look for a rule instance that can still derive a deleted fact

	% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"highway","give_way"],add,_) \ apply_one, fact([yieldSign,X],del,_) <=> 
	fact([yieldSign,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).	

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"highway","stop"],add,_) \ apply_one, fact([stopSign,X],del,_) <=> 
	fact([stopSign,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"highway","traffic_signals"],add,_) \ apply_one, fact([trafficSignal,X],del,_) <=> 
	fact([trafficSignal,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"highway","crossing"],add,_) \ apply_one, fact([pedestrianCrossing,X],del,_) <=> 
	fact([pedestrianCrossing,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"railway","tram_level_crossing"],add,_) \ apply_one, fact([tramCrossing,X],del,_) <=> 
	fact([tramCrossing,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"railway","level_crossing"],add,_) \ apply_one, fact([trainCrossing,X],del,_) <=> 
	fact([trainCrossing,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"public_transport","stop_position"],add,_), 
fact([nodeTag,X,"bus","yes"],add,_), fact([nodeTag,X,"tram","yes"],add,_) 
\ apply_one, fact([intermodalStation,X],del,_) <=> 
	fact([intermodalStation,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"public_transport","stop_position"],add,_), fact([nodeTag,X,"bus","yes"],add,_) 
\ apply_one, fact([busStation,X],del,_) <=> 
	fact([busStation,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"public_transport","stop_position"],add,_), fact([nodeTag,X,"tram","yes"],add,_) 
\ apply_one, fact([tramStation,X],del,_) <=> 
	fact([tramStation,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"amenity","kindergarten"],add,_) \ apply_one, fact([kindergarten,X],del,_) <=> 
	fact([kindergarten,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(1),
fact([way,X],add,Q), fact([wayTag,X,"amenity","kindergarten"],add,_) \ apply_one, fact([kindergarten,X],del,_) <=> 
	fact([kindergarten,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(1),
fact([node,X],add,Q), fact([nodeTag,X,"amenity","school"],add,_) \ apply_one, fact([school,X],del,_) <=> 
	fact([school,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(1),
fact([way,X],add,Q), fact([wayTag,X,"amenity","school"],add,_) \ apply_one, fact([school,X],del,_) <=> 
	fact([school,X],add,Q),
	% enable counting of applied rules per phase
	applied_rules(1,red).	
	


% - apply deletions and new insertions
phase(2) \ fact(_,del,_) <=> true.

% insert remaining pending facts of current query
phase(2), query(_,Q), current_query(Q) \ pending_fact(F,add,Q) <=>
	% variable at end allows mark if needed
	fact(F,add,Q).


%----------	
% -- insertion phase --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */

% do not apply rule if derived fact alread present
fact(F,add,_) \ derived_fact(F,_) <=> true.		


		% node(X), nodeTag(X,"highway","give_way") --> yieldSign(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"highway","give_way"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([yieldSign,X],Q).

	% node(X), nodeTag(X,"highway","stop") --> stopSign(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"highway","stop"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([stopSign,X],Q).

	% node(X), nodeTag(X,"highway","traffic_signals") --> trafficSignal(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"highway","traffic_signals"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([trafficSignal,X],Q).
	
	% node(X), nodeTag(X,"highway","crossing") --> pedestrianCrossing(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"highway","crossing"],add,Q2)  ==>
	member(Q, [Q1, Q2]) |
	derived_fact([pedestrianCrossing,X],Q).
	
	% node(X), nodeTag(X,"railway","tram_level_crossing") --> tramCrossing(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"railway","tram_level_crossing"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([tramCrossing,X],Q).
	
	% node(X), nodeTag(X,"railway","level_crossing") --> trainCrossing(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"railway","level_crossing"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([trainCrossing,X],Q).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), 
	% nodeTag(X,"bus","yes"), nodeTag(X,"bus","yes") --> intermodalStation(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"public_transport","stop_position"],add,Q2), 
fact([nodeTag,X,"bus","yes"],add,Q3), fact([nodeTag,X,"tram","yes"],add,Q4) ==>
	member(Q, [Q1, Q2, Q3, Q4]) |
	derived_fact([intermodalStation,X],Q).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"bus","yes") --> busStation(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"public_transport","stop_position"],add,Q2), fact([nodeTag,X,"bus","yes"],add,Q3) ==>
	member(Q, [Q1, Q2, Q3]) |
	derived_fact([busStation,X],Q).
	
	% node(X), nodeTag(X,"public_transport","stop_position"), nodeTag(X,"tram","yes") --> tramStation(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"public_transport","stop_position"],add,Q2), fact([nodeTag,X,"tram","yes"],add,Q3) ==>
	member(Q, [Q1, Q2, Q3]) |
	derived_fact([tramStation,X],Q).
	
	% node(X), nodeTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"amenity","kindergarten"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([kindergarten,X],Q).
	
	% way(X), wayTag(X,"amenity","kindergarten") --> kindergarten(X)
phase(3), current_query(Q),
fact([way,X],add,Q1), fact([wayTag,X,"amenity","kindergarten"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([kindergarten,X],Q).
	
	% node(X), nodeTag(X,"amenity","school") --> school(X)
phase(3), current_query(Q),
fact([node,X],add,Q1), fact([nodeTag,X,"amenity","school"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([school,X],Q).
	
	% way(X), wayTag(X,"amenity","school") --> school(X)
phase(3), current_query(Q),
fact([way,X],add,Q1), fact([wayTag,X,"amenity","school"],add,Q2) ==>
	member(Q, [Q1, Q2]) |
	derived_fact([school,X],Q).	
		

% insert derived head facts
apply_one, derived_fact(F,Q) <=> 
	fact(F,add,Q),
	% enable counting of applied rules per phase
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
phase(4), current_query(N), query(Q,N), fact(F,add,_), stream(S) ==> 
	unifiable(Q,F,_) |
	writeln(S,F).
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

