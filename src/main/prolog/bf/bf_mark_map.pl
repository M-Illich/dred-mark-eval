/*
Backward/Forward where changes of next update are introduced as marks

map data way connections
	
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	loop/0, read_stream/0, apply_one/0, phase/1,
	available_input/1, extract_input/2,
	query/2, update/2, updt/3, stream_end/0,
	pending_fact/3, fact/4, derived_fact/3,
	next_query_id/1, current_query/1, mark_query/1, create_query/1,
	compute_negative_mark/2, check/5, check_var/2,
	getDel/0,
	clean/0, applied_rules/2, marked_facts/2, marked_facts/3, print/0.

%:- chr_option(debug, off).
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

/*
fact([nextInWay,4,5,3],add,1,_), fact([nextInWay,3,4,3],add,1,_), fact([nextInWay,2,3,2],add,1,_), check(2,2,2,P,M).

*/


% -- statistical information --
% count number of rule applications for each phase
applied_rules(N,P), applied_rules(M,P) <=>
	K is N + M,
	applied_rules(K,P).
		
% distinguish between explicit and implicit facts	
	% explicit
marked_facts(N,add,[nextInWay|_]) <=> marked_facts(N,addEx).	
	% implicit
marked_facts(N,add,[connection|_]) <=> marked_facts(N,addIm).

% count number of marked facts
marked_facts(N,O), marked_facts(M,O) <=>
	K is N + M,
	marked_facts(K,O).
	
% print out collected statistics
print, applied_rules(N,P) ==> writeln(applied_rules(N,P)).
print, marked_facts(N,O) ==> writeln(marked_facts(N,O)).


% remove constraints for simpler output
clean \ fact(_,_,_,_) <=> true.	
clean \ stream(_) <=> true.
clean \ phase(_) <=> true.		
clean \ next_query_id(_) <=> true.	
clean \ current_query(_) <=> true.			
clean \ mark_query(_) <=> true.


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
fact(F,del,Qd,_) \ fact(F,add,Qa,_) <=> Qd >= Qa | true.

% prevent duplicates
fact(F,O,_,_) \ fact(F,O,_,_) <=> true.

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

% if no other query, insert deleted facts of current query
query(_,Q), current_query(Q) \ pending_fact(F,del,Q) <=>
	% variable at end allows mark if needed
	fact(F,del,Q,_).


	% new query is next one
% mark facts that are deleted by next query
query(_,Q), mark_query(Q), fact(F,O,_,M) \ pending_fact(F,del,Q) <=>
	member(O, [add,prv]) |
	% mark fact by assigning value to variable
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
% -- deletions --
% pass deletion on to derived facts if fact cannot be proven
/* Note: we require phase(1) here to make sure 
	that we first perform all explicit deletions 
	before looking for proofs */

% - determine facts to be checked for derivation proof -
phase(1),
fact([nextInWay,X,_,Z1],O1,_,_), fact([nextInWay,X,_,Z2],O2,_,_) \ 
fact([connection,Z1,Z2],add,Q3,_), apply_one <=> 
	Z1 \== Z2,
	member(del,[O1,O2]) |
	fact([connection,Z1,Z2],chk0,Q3,_),
	applied_rules(1,del).

phase(1), 
fact([nextInWay,X,_,Z1],O1,_,_), fact([nextInWay,_,X,Z2],O2,_,_) \ 
fact([connection,Z1,Z2],add,Q3,_), apply_one <=> 
	Z1 \== Z2,
	member(del,[O1,O2]) |
	fact([connection,Z1,Z2],chk0,Q3,_),
	applied_rules(1,del).	
	
phase(1), 
fact([nextInWay,_,X,Z1],O1,_,_), fact([nextInWay,X,_,Z2],O2,_,_) \ 
fact([connection,Z1,Z2],add,Q3,_), apply_one <=> 
	Z1 \== Z2,
	member(del,[O1,O2]) |
	fact([connection,Z1,Z2],chk0,Q3,_),
	applied_rules(1,del).	
	
phase(1), 
fact([nextInWay,_,X,Z1],O1,_,_), fact([nextInWay,_,X,Z2],O2,_,_) \ 
fact([connection,Z1,Z2],add,Q3,_), apply_one <=> 
	Z1 \== Z2,
	member(del,[O1,O2]) |
	fact([connection,Z1,Z2],chk0,Q3,_),
	applied_rules(1,del).	
	
phase(1), 
fact([connection,X,Y],O1,_,_), fact([connection,Y,Z],O2,_,_) \ 
fact([connection,X,Z],add,Q3,_), apply_one <=> 
	member(del,[O1,O2]) |
	fact([connection,X,Z],chk0,Q3,_),
	applied_rules(1,del).


% - check if deleted fact can still be derived -
fact(F,chk0,Q,_) <=>  fact(F,chk,Q,_), getDel.
% directly determine disproved fact after one fact has been checked
getDel, current_query(Q) \ fact(F,chk,_,_) <=> fact(F,del,Q,_).
getDel <=> true.	
	
% only check a fact once
fact(F,chk,_,_) \ fact(F,chk,_,_) <=> true.
% no processing needed if fact already proved
fact(F,prv,_,_) \ fact(F,_,_,_) <=> true.
% use delayed fact as proof
fact(F,dly,Q,M), fact(F,chk,_,_) <=> fact(F,prv,Q,M).

	

% -- backward chaining --
	% X,_ + X,_
fact([connection,Z1,Z2],chk,_,_) \ 
fact([nextInWay,X,Y1,Z1],add,Q1,M1), fact([nextInWay,X,Y2,Z2],add,Q2,M2) <=>
	Z1 \== Z2 |
	fact([nextInWay,X,Y1,Z1],prv,Q1,M1), 
	fact([nextInWay,X,Y2,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z1,Z2],chk,_,_), fact([nextInWay,X,_,Z1],prv,_,_) \
fact([nextInWay,X,Y2,Z2],add,Q2,M2) <=>
	Z1 \== Z2 | 
	fact([nextInWay,X,Y2,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z1,Z2],chk,_,_), fact([nextInWay,X,_,Z2],prv,_,_) \
fact([nextInWay,X,Y1,Z1],add,Q1,M1) <=>
	Z1 \== Z2 | 
	fact([nextInWay,X,Y1,Z1],prv,Q1,M1),
	applied_rules(1,bwd).	
	
	% X,_ + _,X
fact([connection,Z1,Z2],chk,_,_) \ 
fact([nextInWay,X,Y1,Z1],add,Q1,M1), fact([nextInWay,Y2,X,Z2],add,Q2,M2) <=>
	Z1 \== Z2 |
	fact([nextInWay,X,Y1,Z1],prv,Q1,M1), 
	fact([nextInWay,Y2,X,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z1,Z2],chk,_,_), fact([nextInWay,X,_,Z1],prv,_,_) \
fact([nextInWay,Y2,X,Z2],add,Q2,M2) <=>
	Z1 \== Z2 | 
	fact([nextInWay,Y2,X,Z2],prv,Q2,M2),
	applied_rules(1,bwd).	
fact([connection,Z1,Z2],chk,_,_), fact([nextInWay,_,X,Z2],prv,_,_) \
fact([nextInWay,X,Y1,Z1],add,Q1,M1) <=>
	Z1 \== Z2 | 
	fact([nextInWay,X,Y1,Z1],prv,Q1,M1),
	applied_rules(1,bwd).
	
		% _,X + X,_
fact([connection,Z2,Z1],chk,_,_) \ 
fact([nextInWay,X,Y1,Z1],add,Q1,M1), fact([nextInWay,Y2,X,Z2],add,Q2,M2) <=>
	Z1 \== Z2 |
	fact([nextInWay,X,Y1,Z1],prv,Q1,M1), 
	fact([nextInWay,Y2,X,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z2,Z1],chk,_,_), fact([nextInWay,X,_,Z1],prv,_,_) \
fact([nextInWay,Y2,X,Z2],add,Q2,M2) <=>
	Z1 \== Z2 | 
	fact([nextInWay,Y2,X,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z2,Z1],chk,_,_), fact([nextInWay,_,X,Z2],prv,_,_) \
fact([nextInWay,X,Y1,Z1],add,Q1,M1) <=>
	Z1 \== Z2 | 
	fact([nextInWay,X,Y1,Z1],prv,Q1,M1),
	applied_rules(1,bwd).

	% _,X + _,X
fact([connection,Z1,Z2],chk,_,_) \ 
fact([nextInWay,Y1,X,Z1],add,Q1,M1), fact([nextInWay,Y2,X,Z2],add,Q2,M2) <=>
	Z1 \== Z2 |
	fact([nextInWay,Y1,X,Z1],prv,Q1,M1), 
	fact([nextInWay,Y2,X,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z1,Z2],chk,_,_), fact([nextInWay,_,X,Z1],prv,_,_) \
fact([nextInWay,Y2,X,Z2],add,Q2,M2) <=>
	Z1 \== Z2 | 
	fact([nextInWay,Y2,X,Z2],prv,Q2,M2),
	applied_rules(1,bwd).
fact([connection,Z1,Z2],chk,_,_), fact([nextInWay,_,X,Z2],prv,_,_) \
fact([nextInWay,Y1,X,Z1],add,Q1,M1) <=>
	Z1 \== Z2 | 
	fact([nextInWay,Y1,X,Z1],prv,Q1,M1),
	applied_rules(1,bwd).
	
	% trans.
fact([connection,X,Z],chk,_,_) \ 	
fact([connection,X,Y],add,Q1,M1), fact([connection,Y,Z],add,Q2,M2) <=>
	fact([connection,X,Y],chk,Q1,M1), 
	fact([connection,Y,Z],chk,Q2,M2),
	applied_rules(1,bwd).
	
fact([connection,X,Z],chk,_,_) \ 	
fact([connection,X,Y],dly,Q1,M1), fact([connection,Y,Z],dly,Q2,M2) <=>
	fact([connection,X,Y],prv,Q1,M1), 
	fact([connection,Y,Z],prv,Q2,M2),
	applied_rules(1,bwd).
	
fact([connection,X,Z],chk,_,_) \ 	
fact([connection,X,Y],add,Q1,M1), fact([connection,Y,Z],dly,Q2,M2) <=>
	fact([connection,X,Y],chk,Q1,M1), 
	fact([connection,Y,Z],prv,Q2,M2),
	applied_rules(1,bwd).
	
fact([connection,X,Z],chk,_,_) \ 	
fact([connection,X,Y],dly,Q1,M1), fact([connection,Y,Z],add,Q2,M2) <=>
	fact([connection,X,Y],prv,Q1,M1), 
	fact([connection,Y,Z],chk,Q2,M2),
	applied_rules(1,bwd).
	
fact([connection,X,Z],chk,_,_), fact([connection,X,Y],prv,_,_) \
fact([connection,Y,Z],add,Q2,M2) <=>
	fact([connection,Y,Z],chk,Q2,M2),
	applied_rules(1,bwd).	
	
fact([connection,X,Z],chk,_,_), fact([connection,Y,Z],prv,_,_) \
fact([connection,X,Y],add,Q1,M1) <=>
	fact([connection,X,Y],chk,Q1,M1),
	applied_rules(1,bwd).	
	
fact([connection,X,Z],chk,_,_), fact([connection,X,Y],prv,_,_) \
fact([connection,Y,Z],dly,Q2,M2) <=>
	fact([connection,Y,Z],prv,Q2,M2),
	applied_rules(1,bwd).	
	
fact([connection,X,Z],chk,_,_), fact([connection,Y,Z],prv,_,_) \
fact([connection,X,Y],dly,Q1,M1) <=>
	fact([connection,X,Y],prv,Q1,M1),
	applied_rules(1,bwd).	
	
	

% -- forward chaining --
% no delayed, only forward when checked available
fact([nextInWay,X,_,Z1],prv,_,M2), fact([nextInWay,X,_,Z2],prv,_,M3) 
\ fact([connection,Z1,Z2],chk,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],prv,Q1,M),
	applied_rules(1,fwd).

fact([nextInWay,X,_,Z1],prv,_,M2), fact([nextInWay,_,X,Z2],prv,_,M3)  
\ fact([connection,Z1,Z2],chk,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],prv,Q1,M),
	applied_rules(1,fwd).
	
fact([nextInWay,_,X,Z1],prv,_,M2), fact([nextInWay,X,_,Z2],prv,_,M3)  
\ fact([connection,Z1,Z2],chk,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],prv,Q1,M),
	applied_rules(1,fwd).	
	
fact([nextInWay,_,X,Z1],prv,_,M2), fact([nextInWay,_,X,Z2],prv,_,M3)  
\ fact([connection,Z1,Z2],chk,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],prv,Q1,M),
	applied_rules(1,fwd).	
	
fact([connection,X,Y],prv,_,_), fact([connection,Y,Z],prv,_,_)  \ fact([connection,X,Z],chk,Q1,_) <=>
	fact([connection,X,Z],prv,Q1,_),
	applied_rules(1,fwd).	
	
% not-yet-fact is delayed
phase(1), fact([nextInWay,X,_,Z1],prv,_,M2), fact([nextInWay,X,_,Z2],prv,_,M3) 
\ fact([connection,Z1,Z2],add,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],dly,Q1,M),
	applied_rules(1,fwd).

phase(1), fact([nextInWay,X,_,Z1],prv,_,M2), fact([nextInWay,_,X,Z2],prv,_,M3)  
\ fact([connection,Z1,Z2],add,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],dly,Q1,M),
	applied_rules(1,fwd).
	
phase(1), fact([nextInWay,_,X,Z1],prv,_,M2), fact([nextInWay,X,_,Z2],prv,_,M3)  
\ fact([connection,Z1,Z2],add,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],dly,Q1,M),
	applied_rules(1,fwd).	
	
phase(1), fact([nextInWay,_,X,Z1],prv,_,M2), fact([nextInWay,_,X,Z2],prv,_,M3)  
\ fact([connection,Z1,Z2],add,Q1,_) <=>
	Z1 \== Z2 |
	compute_negative_mark([M2,M3], M),
	fact([connection,Z1,Z2],dly,Q1,M),
	applied_rules(1,fwd).	
	
phase(1), fact([connection,X,Y],prv,_,_), fact([connection,Y,Z],prv,_,_)  \ fact([connection,X,Z],add,Q1,_) <=>
	fact([connection,X,Z],dly,Q1,_),
	applied_rules(1,fwd).		

	
	
% apply deletions
phase(2) \ fact(_,del,_,_) <=> true.

% re-insert proven facts
phase(2) \ fact(F,O,Q,M) <=>
	member(O,[prv,dly]) |
	fact(F,add,Q,M).

% insert remaining added facts of current query
phase(2), current_query(Q) \ pending_fact(F,add,Q) <=>
	fact(F,add,Q,_).


%----------	
% -- additions --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */
	
	
% - compute negative mark -
% at least one element in list has to be 1
compute_negative_mark([],_) <=> true.
compute_negative_mark([1|_],M) <=> M = 1.
compute_negative_mark([_|L],M) <=> compute_negative_mark(L,M).

	
% do not apply rule if derived fact alread present
fact(F,add,_,_) \ derived_fact(F,_,_) <=> true.	

phase(3), current_query(Q),
fact([nextInWay,X,_,Z1],add,Q1,M2), fact([nextInWay,X,_,Z2],add,Q2,M3)  ==>
	Z1 \== Z2,
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M2,M3], M),
	derived_fact([connection,Z1,Z2],Q,M).
phase(3), current_query(Q),
fact([nextInWay,X,_,Z1],add,Q1,M2), fact([nextInWay,_,X,Z2],add,Q2,M3)  ==>
	Z1 \== Z2,
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M2,M3], M),
	derived_fact([connection,Z1,Z2],Q,M).
phase(3), current_query(Q),
fact([nextInWay,_,X,Z1],add,Q1,M2), fact([nextInWay,X,_,Z2],add,Q2,M3)  ==>
	Z1 \== Z2,
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M2,M3], M),
	derived_fact([connection,Z1,Z2],Q,M).
phase(3), current_query(Q),
fact([nextInWay,_,X,Z1],add,Q1,M2), fact([nextInWay,_,X,Z2],add,Q2,M3)  ==>
	Z1 \== Z2,
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M2,M3], M),
	derived_fact([connection,Z1,Z2],Q,M).	
phase(3), current_query(Q),
fact([connection,X,Y],add,Q1,_), fact([connection,Y,Z],add,Q2,_)  ==>
	member(Q, [Q1, Q2]) |
	derived_fact([connection,X,Z],Q,_).
	

% insert derived head facts
apply_one \ derived_fact(F,Q,M) <=> 
	fact(F,add,Q,M),
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
phase(4), current_query(N), query(Q,N), fact(F,add,_,_), stream(S) ==> 
	unifiable(Q,F,_) |
	writeln(S,F).	
% mark end of answers in stream
phase(4), stream(S), current_query(N) \ query(_,N) <=> 
	writeln(S,""), 
	flush_output(S).


%----------	
% -- prepare next query --

% transform marked explicit add-facts into del-facts
phase(4), mark_query(Q) \ fact([nextInWay,X,Y,Z],add,_,1) <=> 
	fact([nextInWay,X,Y,Z],del,Q,_),
	marked_facts(1,add,[nextInWay,X,Y,Z]).
% ... and marked implicit add-facts into facts that need to be checked
phase(4), mark_query(Q) \ fact([connection,X,Y],add,_,1) <=> 
	fact([connection,X,Y],chk0,Q,_),
	marked_facts(1,add,[connection,X,Y]).
	
% increase current and mark ID value and reset phase and proofs
phase(4), current_query(_), mark_query(M) <=>
	N is M + 1,
	mark_query(N),
	current_query(M),
	phase(1).
