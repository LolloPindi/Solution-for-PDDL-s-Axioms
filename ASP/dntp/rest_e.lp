conn(X,Y) :- conn(Y,X), X != Y.
close(X,Y) :- close(Y,X), X != Y.

%RESTORE_edge (REST-e)
rco_ex_e(V, U, V_d, U_d) :- 
    secondary(V), primary(U), 
    conn(V,U), 
    conn(V_d,U_d), 
    le(V_d,U_d), 
    (V,U) != (V_d,U_d),           
    (V,U) != (U_d,V_d).          

rco_ex_e(V, U, V_d, U_d) :- 
    secondary(V), primary(U), 
    secondary(W), 
    conn(V,W), 
    conn(V_d,U_d),
    le(V_d, U_d),
    (V,W) != (V_d,U_d), 
    (V,W) != (U_d,V_d), 
    rco_ex_e(W, U, V_d, U_d).

has_safe_connection(V, V_d, U_d) :- 
    secondary(V), 
    conn(V_d, U_d), 
    le(V_d,U_d),
    primary(U),                  
    rco_ex_e(V, U, V_d, U_d).    

:- secondary(V), conn(V_d, U_d), le(V_d,U_d), not has_safe_connection(V, V_d, U_d).