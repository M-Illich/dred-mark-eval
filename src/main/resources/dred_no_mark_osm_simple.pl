/*
rules based on data from
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
	nextInWay/5,  connection/4.

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
clean \ nextInWay(_,_,_,_,_) <=> true.
clean \ connection(_,_,_,_) <=> true.


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
nextInWay(X,Y,Z,del,Qd) \ nextInWay(X,Y,Z,add,Qa) <=> Qd > Qa | true.
connection(X,Y,del,Qd) \ connection(X,Y,add,Qa) <=> Qd > Qa | true.


% prevent duplicates
nextInWay(X,Y,Z,_,_) \ nextInWay(X,Y,Z,_,_) <=> true.
connection(X,Y,_,_) \ connection(X,Y,_,_) <=> true.


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
query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],del,Q) <=>
	nextInWay(X,Y,Z,del,Q).
query(_,Q), current_query(Q) \ pending_fact([connection,X,Y],del,Q) <=>	
	connection(X,Y,del,Q).



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

phase(0), current_query(Q),
nextInWay(X,_,Z1,O1,Q1), nextInWay(X,_,Z2,O2,Q2) 
\ apply_one, connection(Z1,Z2,add,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]])	| 
	connection(Z1,Z2,del,Q),
	applied_rules(1,del).	
	
phase(0), current_query(Q),
nextInWay(X,_,Z1,O1,Q1), nextInWay(_,X,Z2,O2,Q2) 
\ apply_one, connection(Z1,Z2,add,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	connection(Z1,Z2,del,Q),
	applied_rules(1,del).	
	
phase(0), current_query(Q),
nextInWay(_,X,Z1,O1,Q1), nextInWay(_,X,Z2,O2,Q2) 
\ apply_one, connection(Z1,Z2,add,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	connection(Z1,Z2,del,Q),
	applied_rules(1,del).	
	
phase(0), current_query(Q),
connection(X,Y,O1,Q1), connection(Y,Z,O2,Q2) 
\ apply_one, connection(X,Z,add,_)<=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	connection(X,Z,del,Q),
	applied_rules(1,del).		



%----------	
% -- rederivation phase --	
% look for a rule instance that can still derive a deleted fact
	
phase(1), 
nextInWay(X,_,Z1,add,Q), nextInWay(X,_,Z2,add,_) 
\ apply_one, connection(Z1,Z2,del,_)<=> 
	Z1 \== Z2 | 
	connection(Z1,Z2,add,Q),
	applied_rules(1,red).	
	
phase(1), 
nextInWay(X,_,Z1,add,Q), nextInWay(_,X,Z2,add,_) 
\ apply_one, connection(Z1,Z2,del,_)<=> 
	Z1 \== Z2 | 
	connection(Z1,Z2,add,Q),
	applied_rules(1,red).	
	
phase(1), 
nextInWay(_,X,Z1,add,Q), nextInWay(_,X,Z2,add,_) 
\ apply_one, connection(Z1,Z2,del,_)<=> 
	Z1 \== Z2 | 
	connection(Z1,Z2,add,Q),
	applied_rules(1,red).	
	
phase(1), 
connection(X,Y,add,Q), connection(Y,Z,add,_) 
\ apply_one, connection(X,Z,del,_)<=> 
	connection(X,Z,add,Q),
	applied_rules(1,red).		


% - apply deletions
phase(2) \ nextInWay(_,_,_,del,_) <=> true.
phase(2) \ connection(_,_,del,_) <=> true.

% insert remaining pending facts of current query
phase(2), query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],add,Q) <=>
	nextInWay(X,Y,Z,add,Q).
phase(2), query(_,Q), current_query(Q) \ pending_fact([connection,X,Y],add,Q) <=>	
	connection(X,Y,add,Q).



%----------	
% -- insertion phase --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */

% do not apply rule if derived fact alread present
nextInWay(X,Y,Z,add,_) \ derived_fact([nextInWay,X,Y,Z],_) <=> true.	
connection(X,Y,add,_) \ derived_fact([connection,X,Y],_) <=> true.	


phase(3), current_query(Q),
nextInWay(X,_,Z1,add,Q1), nextInWay(X,_,Z2,add,Q2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	derived_fact([connection,Z1,Z2],Q).
	
phase(3), current_query(Q),
nextInWay(X,_,Z1,add,Q1), nextInWay(_,X,Z2,add,Q2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	derived_fact([connection,Z1,Z2],Q).
	
phase(3), current_query(Q),
nextInWay(_,X,Z1,add,Q1), nextInWay(_,X,Z2,add,Q2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	derived_fact([connection,Z1,Z2],Q).	
	
phase(3), current_query(Q),
connection(X,Y,add,Q1), connection(Y,Z,add,Q2) ==>
	member(Q,[Q1,Q2]) | 
	derived_fact([connection,X,Z],Q).		
		

% insert derived head facts
apply_one, derived_fact([nextInWay,X,Y,Z],Q) <=> 	
	nextInWay(X,Y,Z,add,Q),
	applied_rules(1,ins).
apply_one, derived_fact([connection,X,Y],Q) <=> 	
	connection(X,Y,add,Q),
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
	
phase(4), current_query(N), query(Q,N), nextInWay(X,Y,Z,add,_), stream(S) ==> 
	unifiable(Q,[nextInWay,X,Y,Z],_) |
	writeln(S,[nextInWay,X,Y,Z]).
phase(4), current_query(N), query(Q,N), connection(X,Y,add,_), stream(S) ==> 
	unifiable(Q,[connection,X,Y],_) |
	writeln(S,[connection,X,Y]).

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

