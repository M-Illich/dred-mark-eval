/*
read facts rom stream and compute materialization
	i.e., exhaustivel apply rules until no further facts can be derived
*/

:- use_module(library(chr)).
:- chr_constraint init/1, stream/1,
	available_input/1, extract_input/1, end/0,
	node/1, nextInWay/3,  connection/2,
	count/1.

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
extract_input([[node,X]|Xs]) <=>	
	node(X),
	extract_input(Xs).
extract_input([[nextInWay,X,Y,Z]|Xs]) <=>
	nextInWay(X,Y,Z),
	extract_input(Xs).
% exclude irrelevant fats
extract_input([_|Xs]) <=>
	extract_input(Xs).	
	

% remove duplicates
node(X) \ node(X) <=> true.
nextInWay(X,Y,Z) \ nextInWay(X,Y,Z) <=> true.
connection(X,Y) \ connection(X,Y) <=> true.
		

%-------------------------------------------------	
% -- compute materialization --
	
% nextInWay(X,Y,_) ==> connection(X,Y).
% connection(X,Y), nextInWay(Y,Z,_) ==> connection(X,Z).

nextInWay(X,_,Z1), nextInWay(X,_,Z2) ==> Z1 \== Z2 | connection(Z1,Z2).	
nextInWay(_,X,Z1), nextInWay(X,_,Z2) ==> Z1 \== Z2 | connection(Z1,Z2).	
nextInWay(_,X,Z1), nextInWay(_,X,Z2) ==> Z1 \== Z2 | connection(Z1,Z2).	


%-------------------------------------------------	
% -- write all facts to stream --
node(X), stream(S) ==> 	
	writeln(S,[node,X]).
nextInWay(X,Y,Z), stream(S) ==> 
	writeln(S,[nextInWay,X,Y,Z]).
connection(X,Y), stream(S) ==> 
	writeln(S,[connection,X,Y]).
	
% mark end of answers in stream
stream(S), end <=> 
	writeln(S,""), 
	flush_output(S).


