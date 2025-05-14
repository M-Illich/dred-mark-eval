/*
Backward/Forward where changes of next update are introduced as marks

transitive paths

	
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	loop/0, read_stream/0, apply_one/0, phase/1,
	available_input/1, extract_input/2,
	query/2, update/2, updt/3, stream_end/0,
	pending_fact/3, fact/4, derived_fact/3,
	next_query_id/1, current_query/1, mark_query/1, create_query/1,
	compute_negative_mark/2, check/5,
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


% -- statistical information --
% count number of rule applications for each phase
applied_rules(N,P), applied_rules(M,P) <=>
	K is N + M,
	applied_rules(K,P).

		
% distinguish between explicit and implicit facts	
	% explicit
marked_facts(N,add,[edge|_]) <=> marked_facts(N,addEx).	
	% implicit
marked_facts(N,add,[path|_]) <=> marked_facts(N,addIm).

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
	O \== del |
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
	% edge(X,Y) --> path(X,Y)
phase(1), % current_query(Q),
fact([edge,X,Y],del,_Q,_) \ fact([path,X,Y],add,Q2,_), apply_one <=> 
	fact([path,X,Y],chk0,Q2,_),
	applied_rules(1,del).
	
	% edge(X,Y), path(Y,Z) --> path(X,Z)
phase(1), % current_query(Q),
fact([edge,X,Y],O1,_Q1,_), fact([path,Y,Z],O2,_Q2,_) \ fact([path,X,Z],add,Q3,_), apply_one <=> 
	% 	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	member(del,[O1,O2]) |
	fact([path,X,Z],chk0,Q3,_),
	applied_rules(1,del).


/*
fact([edge,0,3],add,0,_), fact([edge,0,1],add,0,_), fact([edge,1,2],add,0,_), fact([edge,2,3],add,0,_), fact([path,0,3],add,0,_), fact([path,0,1],add,0,_), fact([path,1,2],add,0,_), fact([path,2,3],add,0,_), fact([path,0,2],add,0,_), fact([path,1,3],add,0,_), fact([edge,0,3],del,1,_), phase(1), current_query(1), apply_one.

*/

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
fact([path,X,Y],chk,_,_) \ fact([edge,X,Y],add,Q,M) <=>
	fact([edge,X,Y],prv,Q,M),
	applied_rules(1,bwd).	
fact([path,X,Z],chk,_,_) \ fact([edge,X,Y],add,Q1,M1), fact([path,Y,Z],add,Q2,M2) <=>
	fact([edge,X,Y],prv,Q1,M1),
	fact([path,Y,Z],chk,Q2,M2),
	applied_rules(1,bwd).		
fact([path,X,Z],chk,_,_), fact([edge,X,Y],prv,_,_) \ fact([path,Y,Z],add,Q2,M2) <=>
	fact([path,Y,Z],chk,Q2,M2),
	applied_rules(1,bwd).		
fact([path,X,Z],chk,_,_), fact([path,Y,Z],prv,_,_) \ fact([edge,X,Y],add,Q1,M1) <=>
	fact([edge,X,Y],prv,Q1,M1),
	applied_rules(1,bwd).	
fact([path,X,Z],chk,_,_) \ fact([edge,X,Y],add,Q1,M1), fact([path,Y,Z],dly,Q2,M2) <=>
	fact([edge,X,Y],prv,Q1,M1),
	fact([path,Y,Z],prv,Q2,M2),
	applied_rules(1,bwd).	
fact([path,X,Z],chk,_,_),  fact([edge,X,Y],prv,_,_) \ fact([path,Y,Z],dly,Q2,M2) <=>
	fact([path,Y,Z],prv,Q2,M2),
	applied_rules(1,bwd).	

	
% -- forward chaining --
% checked fact is directly proven
fact([edge,X,Y],prv,_,M1) \ fact([path,X,Y],chk,Q,_) <=> 
%	compute_negative_mark([M1],M),
	fact([path,X,Y],prv,Q,M1),
	applied_rules(1,fwd).
fact([edge,X,Y],prv,_,M1), fact([path,Y,Z],prv,_,_) \ fact([path,X,Z],chk,Q1,_) <=>
%	compute_negative_mark([M1],M),
	fact([path,X,Z],prv,Q1,M1),
	applied_rules(1,fwd).		
% not-yet-checked fact is delayed
phase(1), fact([edge,X,Y],prv,_,M1) \ fact([path,X,Y],add,Q,_) <=> 
	% note: we need phase(1) here to prevent that re-adding of add-facts later on causes repeated rule applications here
%	compute_negative_mark([M1],M),
	fact([path,X,Y],dly,Q,M1),
	applied_rules(1,fwd).
phase(1), fact([edge,X,Y],prv,_,M1), fact([path,Y,Z],prv,_,_) \ fact([path,X,Z],add,Q1,_) <=>
%	compute_negative_mark([M1],M),
	fact([path,X,Z],dly,Q1,M1),
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
% single element sufficient here
compute_negative_mark([1],M) <=> M = 1.
compute_negative_mark([_],_) <=> true.
	
% do not apply rule if derived fact alread present
fact(F,add,_,_) \ derived_fact(F,_,_) <=> true.	

	% edge(X,Y) --> path(X,Y)
phase(3), current_query(Q),
fact([edge,X,Y],add,Q,M1) ==> 
%	compute_negative_mark([M1], M),
	derived_fact([path,X,Y],Q,M1).
	
	% edge(X,Y), path(Y,Z) --> path(X,Z)
phase(3), current_query(Q),
fact([edge,X,Y],add,Q1,M1), fact([path,Y,Z],add,Q2,_) ==>
	member(Q, [Q1, Q2]) |
%	compute_negative_mark([M1], M),
	derived_fact([path,X,Z],Q,M1).


% insert derived head facts
apply_one \ derived_fact(F,Q,M) <=> 
	fact(F,add,Q,M),
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
% indicate end of answers in stream
phase(4), stream(S), current_query(N) \ query(_,N) <=> 
	writeln(S,""), 
	flush_output(S).


%----------	
% -- prepare next query --

% transform marked explicit add-facts into del-facts
phase(4), mark_query(Q) \ fact([edge,X,Y],add,_,1) <=> 
	fact([edge,X,Y],del,Q,_),
	marked_facts(1,add,[edge,X,Y]).
% ... and marked implicit add-facts into facts that need to be checked
phase(4) \ fact([path,X,Y],add,Q,1) <=> 
	fact([path,X,Y],chk0,Q,_),
	marked_facts(1,add,[path,X,Y]).

	
% increase current and mark ID value and reset phase and proofs
phase(4), current_query(_), mark_query(M) <=>
	N is M + 1,
	mark_query(N),
	current_query(M),
	phase(1).
