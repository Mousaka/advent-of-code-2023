% Copied from @jasagredo https://github.com/jasagredo/advent-of-prolog-2023/blob/main/src/utils.pl
/**
Provides some utility functions useful for the solutions.
*/

% I have these because otherwise I cannot call lambdas or maplist with filter.
%
% ```
% ?- ['src/2'].
%    true.
% ?- solve2('inputs/2.txt', Sol).
%    error(existence_error(procedure,maplist/3),maplist/3).
% ?- solve2('inputs/2.txt', Sol).
%    error(existence_error(procedure,(\)/3),(\)/3).
% ```
%
% But I don't see anything like this in library(lists), so what am I doing
% wrong? ;_;
:- use_module(library(lists)).
:- use_module(library(lambda)).
:- use_module(library(dcgs)).
:- use_module(library(charsio)).
:- use_module(library(debug)).
:- use_module(library(clpz)).
:- use_module(library(pio)).

:- meta_predicate filter(1, ?, ?).
:- meta_predicate forlist(?, 2, ?).
:- meta_predicate seqof(1, ?).
:- meta_predicate foldl1(3, ?, ?).
:- meta_predicate seqDelimited(?, 1, ?).
:- meta_predicate map_assoc_with_key(2, ?).

ok(X) :- format("~q \33\[32mOK\33\[0m~n", [X]).
ko(X, Y) :- format("~q \33\[31mFAIL (/= ~q)\33\[0m~n", [X, Y]).

isok(X, Y) :-
    X #= Y, ok(X); ko(X, Y).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                            File parsing DCGs                               %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% The Power of Prolog
lines([])           --> call(eos), !.
lines([Line|Lines]) --> line(Line), lines(Lines).

line([])     --> ( "\n" ; call(eos) ), !.
line([L|Ls]) --> [L], line(Ls).

eos([], []).

eol --> ("\n"; call(eos)).

:- op(900, fx, @).

trunc(X1, X2) :- trunc(10, X1, X2), !.
trunc(0, _, "...") :- !.
trunc(_, [], []).
trunc(N, [X|X1], [X|X2]) :- N1 #= N - 1, trunc(N1, X1, X2).

@(G_0, In, Out) :-
   trunc(100, In, In1),
   format("dcg:call(~q) <- ~s~n", [G_0, In1]),
   phrase(G_0, In, Out),
   trunc(100, Out, Out1),
   format("dcg:exit(~q) -> ~s~n", [G_0, Out1]).

seqDelimited(_, _, []) --> eol.
seqDelimited(_, Each, [S]) --> call(Each, S).
seqDelimited(' ', Each, [S|Ss]) -->
    call(Each, S),
    seqof(whitespace, _),
    seqDelimited(' ', Each, Ss).
seqDelimited(Del, Each, [S|Ss]) -->
    call(Each, S),
    seqof(whitespace, _),
    [Del],
    seqof(whitespace, _),
    seqDelimited(Del, Each, Ss).

seqof(P, [S|Ss]) --> [S], {call(P, S)}, seqof(P, Ss).
seqof(_, []) --> [].
seqof_(P) --> seqof(P,_).

number(X) --> number([], X).
number(X, Z) --> [C], { char_type(C, numeric) }, number([C|X], Z).
number(X, Z) --> { length(X, L), L #> 0, reverse(X, X1), number_chars(Z, X1) }.
znumber(X) --> "-", number(Y), { X #= -Y }; number(X).
a_digit(X) --> [X], {char_type(X, numeric)}.

% From Power of Prolog video
integer(I) --> digits(Ds), {number_chars(I,Ds)}.
digits([D|Ds]) --> digit(D), digits_r(Ds).
digits_r([D|Ds]) --> digit(D), digits_r(Ds).
digits_r([]) --> [].
digit(D) --> [D], { char_type(D, decimal_digit)}.

word([X|Xs]) --> [X], { char_type(X, alnum) }, word(Xs).
word([]) --> "".

whitespace(' ').
ws --> [W], { char_type(W, whitespace) }, ws | []. % Aribtrary length of ws. From Power of Prolog video.
non_zero_ws --> [W], { char_type(W, whitespace) }, ws. 
numeric(X) :- char_type(X, numeric).
alpha(X) :- char_type(X, alpha).
alnum(X) :- char_type(X, alnum).

%%%% from metalevel
include(Goal, List, Included) :-
        phrase(include_(List, Goal), Included).

include_([], _) --> [].
include_([L|Ls], Goal) -->
        (   { call(Goal, L) } ->
            [L]
        ;   []
        ),
        include_(Ls, Goal).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                 Lists                                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filter(_, [], []).
filter(G_1, [X|Xs], ZZs) :-
    filter(G_1, Xs, Zs),
    ( call(G_1, X)
    -> ZZs = [X|Zs]
    ; ZZs = Zs
    ).

forlist(In, G_2, Out) :- maplist(G_2, In, Out).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%                                 Catches                                    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

number_string(N, S) :-
    catch(number_chars(N, S), _, false).

foldl1(F, [L|Ls], R) :-
    foldl(F, Ls, L, R).

or(X, Y, X\/Y).

plus(N, X, Y) :-
    Y #= X + N.

minus(N, X, Y) :-
    Y #= X - N.

eq(X, Y) :- Y #= X.

fst(X-_,X).
snd(_-X,X).



map_assoc_with_key(Pred, T) :-
    map_assoc_with_key_(T, Pred).

map_assoc_with_key_(t, _).
map_assoc_with_key_(t(K,Val,_,L,R), Pred) :-
    map_assoc_with_key_(L, Pred),
    call(Pred, K, Val),
    map_assoc_with_key_(R, Pred).


bubblesort(Ls0, Ls) :-
    (	append(Lefts, [A,B|Rights], Ls0), A @> B ->
	append(Lefts, [B,A|Rights], Ls1),
	bubblesort(Ls1, Ls)
    ;	Ls = Ls0
    ).


mergesort(Ls0, Ls) :-
        length(Ls0, L),
        zcompare(C, L, 1),
        halving(C, L, Ls0, Ls).

halving(<, _, Ls, Ls).
halving(=, _, Ls, Ls).
halving(>, L, Ls0, Ls) :-
        Half #= L // 2,
        length(Lefts0, Half),
        append(Lefts0, Rights0, Ls0),
        mergesort(Lefts0, Lefts),
        mergesort(Rights0, Rights),
        merge(Lefts, Rights, Ls).

% If your Prolog library provides merge/3, you can remove this definition.

merge([], Ys, Ys) :- !.
merge(Xs, [], Xs) :- !.
merge([X|Xs], [Y|Ys], Ms) :-
        (   X @< Y ->
            Ms = [X|Rs],
            merge(Xs, [Y|Ys], Rs)
        ;   Ms = [Y|Rs],
            merge([X|Xs], Ys, Rs)
        ).