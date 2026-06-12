conn(X,Y) :- conn(Y,X), X != Y.
close(X,Y) :- close(Y,X), X!= Y.

%rc encoding
rc(V,U) :- conn(V,U), close(V,U).
rc(V,U) :- node(W), W!=V, conn(V,W), close(V,W), rc(W,U).

% rad encoding (1)
secondary_has_primary(S,P) :- secondary(S), primary(P), rc(S,P).
number_of_primary(S, Num) :- secondary(S), Num = #count{P : secondary_has_primary(S,P)}. 

:- number_of_primary(_,Num), Num = 0.
:- number_of_primary(_,Num), Num > 1.

%rad encoding(2)
:- primary(P1), primary(P2), le(P1,P2), rc(P1,P2).