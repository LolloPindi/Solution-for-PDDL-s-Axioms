% 1. ASSIOMA ASP (Regola Derivata): 
% Un robot è in pericolo se è alimentato (da PDDL) e necessita manutenzione (Statico)
danger(R) :- is_powered(R), needs_maintenance(R).

% 2. VINCOLO DI INTEGRITÀ (Pruning):
% E' vietato esplorare uno stato in cui un robot in pericolo si sta muovendo!
:- moving(R), danger(R).