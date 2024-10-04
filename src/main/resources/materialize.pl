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
		

%-------------------------------------------------	
% -- compute materialization --
	% edge(X,Y) --> path(X,Y)
fact([edge,X,Y]) ==> fact([path,X,Y]).
	
	% edge(X,Y), path(Y,Z) --> path(X,Z)
fact([edge,X,Y]), fact([path,Y,Z]) ==> fact([path,X,Z]).


%-------------------------------------------------	
% -- write all facts to stream --
fact(F), stream(S) ==> 
	writeln(S,F).
% mark end of answers in stream
stream(S), end <=> 
	writeln(S,""), 
	flush_output(S).


