/*
DRed where changes of next query are introduced as marks

general idea:
- collect and combine updates from stream until a query appears
- if some query is currently processed, then
	- if no other query given, we mark facts that are changed by new, combined update
	- if another query already waiting, then wait with marking until query is next to be processed
-> marks only refer to next pending query	
	


pending(Fact,add/del,ID)
current_query(ID)
mark_query(ID)
next_query_id(ID)
query(Q,ID)

--> 
- we first introduce facts as pending and associate it with next available query ID
- two pending with same fact and ID remove each other (thus, updates are combined)
- when new query introduced by stream, it gets the next query ID, and we increase the next value
- when query processing finished, current and mark (i.e., current+1) query ID is increased
- query only processed when equal to current query ID, 
	then related pending is transformed into fact constraint
	but: first only del, 
		then later when insertion phase starts, also remaining pending add facts
	
- after rederivation, we check for each del-fact if it is marked
	if yes, then it is transformed into a pending fact with mark query ID
	else, fact is just removed
- after insertion and answering query, we check remaining add facts for mark
	if marked, then fact is transformed into del
	else do nothing
	
- general problem:
	changing mark can lead to repeated rule applications
	-> idea: use variable if not marked
			assigning value to variabe then serves as marking
			without deleting+re-adding fact
		-> this might also enable us to mark a fact even if it has already been derived
			if we pass on the same variable
			e.g., A(X)-->B(X) will also mark B if A is marked via X

- a fact is marked if there is a pending duplicate that has mark query ID,	
	we then also remove pending

- phase constraint used to separate overdeletion, rederivation, and insertion
- current query constraint used in rule applications
	to ensure that at least one new introduced fact used
	thus, repetitions avoided, too
	
?- should we only read two queries from stream
	and then block further readings until one query finished
	- because only next query actually relevant for marking
*- maybe better to keep it more general
	i.e., also allow further input,
	for case that we want to test approach with several marks
	- although we might control reading by introduction of certain constraint
		and change way/time of introduction based on approach
	
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	loop/0, read_stream/0, apply_one/0, phase/1, 
	available_input/1, extract_input/2,
	query/2, update/2, updt/3, stream_end/0,
	pending_fact/3, fact/4, derived_fact/3,
	next_query_id/1, current_query/1, mark_query/1,
	compute_positive_mark/2, compute_negative_mark/2,
	clean/0, applied_rules/2, marked_facts/2, marked_facts/3, print/0.

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
		
% distinguish between explicit and implicit facts	
	% explicit
marked_facts(N,add,[edge|_]) <=> marked_facts(N,addEx).	
marked_facts(N,del,[edge|_]) <=> marked_facts(N,delEx).	
	% implicit
marked_facts(N,add,[path|_]) <=> marked_facts(N,addIm).
marked_facts(N,del,[path|_]) <=> marked_facts(N,delIm).

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
stream_end, query(_,_) \ query(_,_) <=> true.
	% prevent waiting for next input
stream_end \ read_stream <=> true.
	% stop loop when all updates are fully processed
stream_end, apply_one, loop <=> true.


% remove changes that cancel each other
pending_fact(F,add,Q), pending_fact(F,del,Q) <=> true.

% new del-fact replaces old add-fact
fact(F,del,Qd,_) \ fact(F,add,Qa,_) <=> Qd > Qa | true.

% prevent duplicates
fact(F,_,_,_) \ fact(F,_,_,_) <=> true.
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
available_input([S]), next_query_id(N) <=>
	% read added and deleted facts from stream
	read_line_to_string(S,A),
	read_line_to_string(S,D),	
	extract_input(A,D),
	% insert query asking for every fact
	M is N + 1,
	next_query_id(M),
	query(Q,N).


%----------
% -- input is a query --
% if no other query, insert delete-facts of current query
query(_,Q), current_query(Q) \ pending_fact(F,del,Q) <=>
	% variable at end allows mark if needed
	fact(F,del,Q,_).

	% new query is next one
% mark facts that are changed by next query
query(_,Q), mark_query(Q), fact(F,O1,_,M) \ pending_fact(F,O2,Q) <=>
	O1 \== O2 |
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
% -- overdeletion phase --
% pass deletion on to derived facts

	% edge(X,Y) --> path(X,Y)
phase(0), current_query(Q),
fact([edge,X,Y],del,Q,M) \ apply_one, fact([path,X,Y],add,_,_) <=> 
	fact([path,X,Y],del,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,del).	
	
	% edge(X,Y), path(Y,Z) --> path(X,Z)
phase(0), current_query(Q),
fact([edge,X,Y],O1,Q1,M1), fact([path,Y,Z],O2,Q2,M2) \ apply_one, fact([path,X,Z],add,_,_) <=> 
	member([del,Q],[[O1,Q1],[O2,Q2]]) |
	compute_positive_mark([(O1,M1,ex), (O2,M2,im)],M),
	fact([path,X,Z],del,Q,M),
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

/*
TEST INPUT:
phase(0), current_query(1), fact([edge,1,2],del,1,1), fact([path,2,3],add,0,M2), fact([path,1,3],add,0,M3), apply_one.
phase(0), current_query(1), fact([edge,1,2],add,0,M1), fact([path,2,3],del,1,1), fact([path,1,3],add,0,M3), apply_one.
*/


%----------	
% -- rederivation phase --	
% look for a rule instance that can still derive a deleted fact

	% edge(X,Y) --> path(X,Y)
phase(1),
fact([edge,X,Y],add,Q,M) \ apply_one, fact([path,X,Y],del,_,_) <=> 
	fact([path,X,Y],add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).		
	
	% edge(X,Y), path(Y,Z) --> path(X,Z)
phase(1),
fact([edge,X,Y],add,Q,M1), fact([path,Y,Z],add,_,M2) \ apply_one, fact([path,X,Z],del,_,_) <=>
	compute_negative_mark([M1, M2], M),
	fact([path,X,Z],add,Q,M),
	% enable counting of applied rules per phase
	applied_rules(1,red).		


% - compute negative mark -
/* at least one element in list has to be 1*/
compute_negative_mark([],_) <=> true.
compute_negative_mark([1|_],M) <=> M = 1.
compute_negative_mark([_|L],M) <=> compute_negative_mark(L,M).


% - apply deletions and new insertions
% keep marked del-facts for next query and remove rest
phase(2), mark_query(Q) \ fact(F,del,_,1) <=> 
	pending_fact(F,add,Q),
	% enable counting of marked facts
	marked_facts(1,del,F).
phase(2) \ fact(_,del,_,M) <=> var(M) | true.

% insert remaining pending facts of current query
phase(2), query(_,Q), current_query(Q) \ pending_fact(F,add,Q) <=>
	% variable at end allows mark if needed
	fact(F,add,Q,_).


%----------	
% -- insertion phase --	
/* we first use propagation rules to ensure that a rule instance is only considered once 
	(re-inserting apply_one-constraint can re-trigger application) */
	
% do not apply rule if derived fact alread present
fact(F,add,_,_) \ derived_fact(F,_,_) <=> true.	

	% edge(X,Y) --> path(X,Y)
phase(3), current_query(Q),
fact([edge,X,Y],add,Q,M) ==> derived_fact([path,X,Y],Q,M).
	
	% edge(X,Y), path(Y,Z) --> path(X,Z)
phase(3), current_query(Q),
fact([edge,X,Y],add,Q1,M1), fact([path,Y,Z],add,Q2,M2) ==>
	member(Q, [Q1, Q2]) |
	compute_negative_mark([M1, M2], M),
	derived_fact([path,X,Z],Q,M).


% insert derived head facts
apply_one, derived_fact(F,Q,M) <=> 
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

% transform marked add-facts into del-facts for next query
phase(4), mark_query(Q) \ fact(F,add,_,1) <=> 
	fact(F,del,Q,_),
	% enable counting of marked facts
	marked_facts(1,add,F).
	
% increase current and mark ID value and reset phase
phase(4), current_query(_), mark_query(M) <=>
	N is M + 1,
	mark_query(N),
	current_query(M),
	phase(0).
