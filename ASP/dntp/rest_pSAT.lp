conn(X,Y) :- conn(Y,X), X != Y.
close(X,Y) :- close(Y,X), X != Y.

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