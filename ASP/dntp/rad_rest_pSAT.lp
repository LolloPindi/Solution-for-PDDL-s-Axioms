conn(X,Y) :- conn(Y,X), X != Y.
close(X,Y) :- close(Y,X), X != Y.

%PART 1: RADIALITY (RAD)%

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

%PART 2: N-1 CONNECTIVITY (REST)%

%RESTORE_primary (REST-p)
rco_ex_s(V,U,V_d) :- 
    conn(V,U), 
    primary(U), 
    primary(V_d),
    secondary(V),
    V != V_d, 
    U != V_d.

rco_ex_s(V,U,V_d) :- 
    secondary(V),
    primary(U),
    primary(V_d),
    V != V_d, 
    U != V_d,
    secondary(W), 
    conn(V,W), 
    rco_ex_s(W,U,V_d).

safe_from(V, V_d) :-
    secondary(V), 
    primary(V_d), 
    primary(U),
    rco_ex_s(V, U, V_d).

:- secondary(V), primary(V_d), not safe_from(V, V_d).