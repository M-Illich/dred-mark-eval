/*
DRed where changes of next query are introduced as marks

rules based on data from
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
	nextInWay/6, connection/5.

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
clean \ nextInWay(_,_,_,_,_,_) <=> true.
clean \ connection(_,_,_,_,_) <=> true.	



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
nextInWay(X,Y,Z,del,Qd,_) \ nextInWay(X,Y,Z,add,Qa,_) <=> Qd > Qa | true.
connection(X,Y,del,Qd,_) \ connection(X,Y,add,Qa,_) <=> Qd > Qa | true.


% prevent duplicates
nextInWay(X,Y,Z,_,_,_) \ nextInWay(X,Y,Z,_,_,_) <=> true.
connection(X,Y,_,_,_) \ connection(X,Y,_,_,_) <=> true.

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
query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],del,Q) <=>
	nextInWay(X,Y,Z,del,Q,_).
query(_,Q), current_query(Q) \ pending_fact([connection,X,Y],del,Q) <=>	
	connection(X,Y,del,Q,_).
	

	% new query is next one
% mark facts that are changed by next query by assigning value 1 to variable	
query(_,Q), mark_query(Q), nextInWay(X,Y,Z,O1,_,M) \ pending_fact([nextInWay,X,Y,Z],O2,Q) <=>
	O1 \== O2 |
	M = 1.
query(_,Q), mark_query(Q), connection(X,Y,O1,_,M) \ pending_fact([connection,X,Y],O2,Q) <=>
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

phase(0), current_query(Q),
nextInWay(X,_,Z1,O1,Q1,M1), nextInWay(X,_,Z2,O2,Q2,M2) 
\ apply_one, connection(Z1,Z2,add,_,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]])	| 
	compute_positive_mark([(O1,M1,ex),(O2,M2,ex)],M),
	connection(Z1,Z2,del,Q,M),
	applied_rules(1,del).	
	
phase(0), current_query(Q),
nextInWay(X,_,Z1,O1,Q1,M1), nextInWay(_,X,Z2,O2,Q2,M2) 
\ apply_one, connection(Z1,Z2,add,_,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	compute_positive_mark([(O1,M1,ex),(O2,M2,ex)],M),
	connection(Z1,Z2,del,Q,M),
	applied_rules(1,del).	
	
phase(0), current_query(Q),
nextInWay(_,X,Z1,O1,Q1,M1), nextInWay(X,_,Z2,O2,Q2,M2) 
\ apply_one, connection(Z1,Z2,add,_,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	compute_positive_mark([(O1,M1,ex),(O2,M2,ex)],M),
	connection(Z1,Z2,del,Q,M),
	applied_rules(1,del).	
	
phase(0), current_query(Q),
nextInWay(_,X,Z1,O1,Q1,M1), nextInWay(_,X,Z2,O2,Q2,M2) 
\ apply_one, connection(Z1,Z2,add,_,_)<=> 
	Z1 \== Z2,
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	compute_positive_mark([(O1,M1,ex),(O2,M2,ex)],M),
	connection(Z1,Z2,del,Q,M),
	applied_rules(1,del).	

phase(0), current_query(Q),
connection(X,Y,O1,Q1,M1), connection(Y,Z,O2,Q2,M2) 
\ apply_one, connection(X,Z,add,_,_)<=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) | 
	compute_positive_mark([(O1,M1,ex),(O2,M2,ex)],M),
	connection(X,Z,del,Q,M),
	applied_rules(1,del).		

% phase(0), current_query(Q),
% connection(X,Y,del,Q,M1) 
% \ apply_one, connection(Y,X,add,_,_)<=> 
	% compute_positive_mark([(del,M1,ex)],M),
	% connection(Y,X,del,Q,M),
	% applied_rules(1,del).		

	
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

phase(1), 
nextInWay(X,_,Z1,add,Q,M1), nextInWay(X,_,Z2,add,_,M2) 
\ apply_one, connection(Z1,Z2,del,_,_)<=> 
	Z1 \== Z2 | 
	compute_negative_mark([M1, M2], M),
	connection(Z1,Z2,add,Q,M),
	applied_rules(1,red).	
	
phase(1), 
nextInWay(X,_,Z1,add,Q,M1), nextInWay(_,X,Z2,add,_,M2) 
\ apply_one, connection(Z1,Z2,del,_,_)<=> 
	Z1 \== Z2 | 
	compute_negative_mark([M1, M2], M),
	connection(Z1,Z2,add,Q,M),
	applied_rules(1,red).	
	
phase(1), 
nextInWay(_,X,Z1,add,Q,M1), nextInWay(X,_,Z2,add,_,M2) 
\ apply_one, connection(Z1,Z2,del,_,_)<=> 
	Z1 \== Z2 | 
	compute_negative_mark([M1, M2], M),
	connection(Z1,Z2,add,Q,M),
	applied_rules(1,red).		
	
phase(1), 
nextInWay(_,X,Z1,add,Q,M1), nextInWay(_,X,Z2,add,_,M2) 
\ apply_one, connection(Z1,Z2,del,_,_)<=> 
	Z1 \== Z2 | 
	compute_negative_mark([M1, M2], M),
	connection(Z1,Z2,add,Q,M),
	applied_rules(1,red).	
	
phase(1), 
connection(X,Y,add,Q,M1), connection(Y,Z,add,_,M2) 
\ apply_one, connection(X,Z,del,_,_)<=> 
	compute_negative_mark([M1, M2], M),
	connection(X,Z,add,Q,M),
	applied_rules(1,red).		
	
% phase(1), 
% connection(X,Y,add,Q,M1)
% \ apply_one, connection(Y,X,del,_,_)<=> 
	% compute_negative_mark([M1], M),
	% connection(Y,X,add,Q,M),
	% applied_rules(1,red).			


% - compute negative mark -
/* at least one element in list has to be 1*/
compute_negative_mark([],_) <=> true.
compute_negative_mark([1|_],M) <=> M = 1.
compute_negative_mark([_|L],M) <=> compute_negative_mark(L,M).


% - apply deletions and new insertions
% keep marked del-facts for next query and remove rest
phase(2), mark_query(Q) \ nextInWay(X,Y,Z,del,_,1) <=>
	pending_fact([nextInWay,X,Y,Z],add,Q),
	marked_facts(1,delEx).
phase(2), mark_query(Q) \ connection(X,Y,del,_,1) <=>	
	pending_fact([connection,X,Y],add,Q),
	marked_facts(1,delIm).
	
	
% remove non-marked facts
phase(2) \ nextInWay(_,_,_,del,_,M) <=> var(M) | true.
phase(2) \ connection(_,_,del,_,M) <=> var(M) | true.


% insert remaining pending facts of current query
phase(2), query(_,Q), current_query(Q) \ pending_fact([nextInWay,X,Y,Z],add,Q) <=>
	nextInWay(X,Y,Z,add,Q,_).
phase(2), query(_,Q), current_query(Q) \ pending_fact([connection,X,Y],add,Q) <=>	
	connection(X,Y,add,Q,_).
	


%----------	
% -- insertion phase --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */
	
% do not apply rule if derived fact alread present
nextInWay(X,Y,Z,add,_,_) \ derived_fact([nextInWay,X,Y,Z],_,_) <=> true.	
connection(X,Y,add,_,_) \ derived_fact([connection,X,Y],_,_) <=> true.


phase(3), current_query(Q),
nextInWay(X,_,Z1,add,Q1,M1), nextInWay(X,_,Z2,add,Q2,M2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	compute_negative_mark([M1, M2], M),
	derived_fact([connection,Z1,Z2],Q,M).
	
phase(3), current_query(Q),
nextInWay(X,_,Z1,add,Q1,M1), nextInWay(_,X,Z2,add,Q2,M2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	compute_negative_mark([M1, M2], M),
	derived_fact([connection,Z1,Z2],Q,M).
	
phase(3), current_query(Q),
nextInWay(_,X,Z1,add,Q1,M1), nextInWay(X,_,Z2,add,Q2,M2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	compute_negative_mark([M1, M2], M),
	derived_fact([connection,Z1,Z2],Q,M).	
	
phase(3), current_query(Q),
nextInWay(_,X,Z1,add,Q1,M1), nextInWay(_,X,Z2,add,Q2,M2) ==>
	Z1 \== Z2,
	member(Q,[Q1,Q2]) | 
	compute_negative_mark([M1, M2], M),
	derived_fact([connection,Z1,Z2],Q,M).

phase(3), current_query(Q),
connection(X,Y,add,Q1,M1), connection(Y,Z,add,Q2,M2) ==>
	member(Q,[Q1,Q2]) | 
	compute_negative_mark([M1, M2], M),
	derived_fact([connection,X,Z],Q,M).
	
% phase(3), current_query(Q),
% connection(X,Y,add,Q,M1) ==>
	% compute_negative_mark([M1], M),
	% derived_fact([connection,Y,X],Q,M).	


% insert derived head facts
apply_one, derived_fact([nextInWay,X,Y,Z],Q,M) <=> 	
	nextInWay(X,Y,Z,add,Q,M),
	applied_rules(1,ins).
apply_one, derived_fact([connection,X,Y],Q,M) <=> 	
	connection(X,Y,add,Q,M),
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


phase(4), current_query(N), query(Q,N), nextInWay(X,Y,Z,add,_,_), stream(S) ==> 
	unifiable(Q,[nextInWay,X,Y,Z],_) |
	writeln(S,[nextInWay,X,Y,Z]).
phase(4), current_query(N), query(Q,N), connection(X,Y,add,_,_), stream(S) ==> 
	unifiable(Q,[connection,X,Y],_) |
	writeln(S,[connection,X,Y]).
	
% mark end of answers in stream
phase(4), stream(S), current_query(N) \ query(_,N) <=> 
	writeln(S,""), 
	flush_output(S).

%----------	
% -- prepare next query --

% transform marked add-facts into del-facts for next query
phase(4), mark_query(Q) \ nextInWay(X,Y,Z,add,_,1) <=>
	nextInWay(X,Y,Z,del,Q,_),
	marked_facts(1,addEx).
phase(4), mark_query(Q) \ connection(X,Y,add,_,1) <=>	
	connection(X,Y,del,Q,_),
	marked_facts(1,addIm).
	
	
% increase current and mark ID value and reset phase
phase(4), current_query(_), mark_query(M) <=>
	N is M + 1,
	mark_query(N),
	current_query(M),
	phase(0).
