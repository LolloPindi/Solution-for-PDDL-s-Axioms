% connectivity.lp - valuta "connected" su UNO stato del grafo.
% INPUT dal bridge: edge(X,Y) per gli archi costruiti, node(X) auto-scoperti.
e(X,Y) :- edge(X,Y).
e(X,Y) :- edge(Y,X).
% radice = nodo "minimo" (uno qualsiasi va bene per la connettivita')
not_root(X) :- node(X), node(Y), Y < X.
root(X)     :- node(X), not not_root(X).
reach(X) :- root(X).
reach(Y) :- reach(X), e(X,Y).
unreached :- node(X), not reach(X).
connected :- not unreached.
#show connected/0.
