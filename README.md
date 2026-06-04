# Solution-for-PDDL-s-Axioms
This project implements an extension of the Fast Downward Planner that allows evaluating complex derived predicates (axioms) within a PDDL domain by delegating the computation to an ASP solver (Clingo).

The main goal is to overcome the expressive limitations of standard PDDL in scenarios where state verification requires purely relational or recursive computations (such as the connectivity of a graph or the validity of a Hamiltonian path).

Solution Architecture

The architecture is based on a hybrid/coupled approach that operates at runtime when searching the state space.Translation Phase (Translator): The domain and PDDL instance file are processed normally by Fast Downward's Python translator, producing a SAS+ representation. Predicates to be computed by ASP are defined as derived predicates (axioms).State Generation (Fast Downward Search): During the search (e.g. algorithm $A^*$), Fast Downward generates a new state by applying a PDDL action.Bridge C++ $\leftrightarrow$ Clingo (Shared Library): Before evaluating target constraints or preconditions, the current PDDL state is converted to an ASP fact set (e.g. visited(n1, n2) or link(n1, n2)).External Evaluation (Solver): The search engine invokes the Clingo library APIs by passing current state facts and logical encoding (e.g., connectivity.lp). Clingo calculates the Answer Set and returns the truth value of the control predicate (e.g. connected) to the planner.

Code Changes and Methods Operation
To achieve this integration, the C++ code of the Fast Downward search engine was modified by introducing an interface module with Clingo. The point-by-point operation of the key methods introduced (clingo_init and override mechanisms) is explained below.

1: clingo_init (Solver Initialization)
This method is invoked only once when the search module starts, while reading the input SAS+ file.

What it does: Initializes the Clingo control object (Clingo::Control), configures the basic parameters, and loads the user-specified global ASP encoding into memory via environment variables.

How it works: Reads the path to the.lp file (e.g. via getenv("DNTP_EVAL")) and any static background facts file. Performs preliminary parsing of logical rules. This avoids having to reload and recompile ASP encoding to each individual state, dramatically optimizing computation times.

2: PDDL State Extraction and Fact Mapping
Within the Fast Downward status assessment cycle, an interception method was inserted.

What it does: Converts the current SAS+ state variables into the corresponding ASP logic atoms.

How it works: It loops through the planner's variable dictionary. If a variable associated with a monitored predicate (e.g., a build action or movement) is active in the current state, the bridge generates a string formatted as ASP (e.g., "edge(n1,n2).").

3: Axiom Computation Override 
In the standard Fast Downward, axioms are computed internally by applying fixed Datalog-type rules. This mechanism has been overridden (override).

What it does: It suspends the internal evaluation of Fast Downward for the specific target atom (the "gate") and questions Clingo.

How it works point by point:

A new temporary grounding sub-pass is started on the Clingo solver, inserting the extracted facts from the current state (Point 2).

Clingo's solving procedure via C++ API is launched.

The bridge examines the resulting stable models (Answer Sets): if the monitored atom (e.g. connected or valid_route) is present in the model, the method overrides by setting the value of the SAS+ variable to true (or its respective activation value). Otherwise, it is forced to false.

Reset of temporary facts is performed to prepare the solver for the next state.

3. Guide to Starting the Program
Below are the commands to run in the Linux terminal to configure the environment and run the benchmark on the graph instances.

Step 1: Configuring Environment Variables
It is essential to export the correct paths for the C++ executable to find the Clingo dynamic library and application files

# Configure the Clingo shared library
export LD_LIBRARY_PATH=/home/lollo/clingo-system/lib:$LD_LIBRARY_PATH

# Clean up any residual previous static facts
unset DNTP_FACTS

# Set ASP encoding path for graph connectivity
export DNTP_EVAL=/home/XXX/ProjectPDDl/Solution-for-PDDL-s-Axioms/ASP/graph-connectivity/connectivity.lp


#Select the Planner 
cd /home/XXX/ProgettoPDDl/Solution-for-PDDL-s-Axioms/FastDownward

#Execute
./fast-downward.py \
  /home/lollo/ProgettoPDDl/Solution-for-PDDL-s-Axioms/ASP/graph-connectivity/domain.pddl \
  /home/lollo/ProgettoPDDl/Solution-for-PDDL-s-Axioms/ASP/graph-connectivity/instances/g10_scale.pddl \
  --search "astar(blind())"
  
  
#If you want to see all the results:
printf "%-22s | %-6s | %-9s | %s\n" "istanza" "nodi" "atteso" "risultato"
printf -- "-----------------------+--------+-----------+------------------\n"
for f in /home/lollo/ProgettoPDDl/Solution-for-PDDL-s-Axioms/ASP/graph-connectivity/instances/*.pddl; do
  rm -f sas_plan
  ./fast-downward.py /home/lollo/ProgettoPDDl/Solution-for-PDDL-s-Axioms/ASP/graph-connectivity/domain.pddl "$f" --search "astar(blind())" >/tmp/r.log 2>&1
  nodi=$(grep -oE 'n[0-9]+' "$f" | sort -u | wc -l)
  atteso=$((nodi-1))
  if grep -q "Solution found" /tmp/r.log; then
     b=$(grep -c '^(build' sas_plan)
     res="SOLVED, $b build"
  else
     res="NO PLAN (unsat)"
  fi
  printf "%-22s | %-6s | %-9s | %s\n" "$(basename $f .pddl)" "$nodi" "$atteso" "$res"
done

#Ifyou want to se all the plans:
cat sas_plan




#SPIEGAZIONE DI COME SONO STATI PENSATI CLINGO INIT E CLINGO OVERRIDE

clingo_init (Viene eseguito solo una volta all'avvio)

Esplora tutte le variabili che il pianificatore ha estratto dal problema PDDL.

Se trova una variabile derivata 0-aria (ovvero un cancello globale come rad o restore che ha un dominio di dimensione 2, cioè Vero/Falso), la inserisce in una tabella speciale chiamata gate_var. Memorizza l'associazione: "nome_testuale" -> ID_numerico_della_variabile.

Per tutte le altre variabili (i fluenti normali come la presenza di un arco o lo stato chiuso/aperto di un interruttore), pulisce i nomi (es. trasforma "Atom conn(s1, p2)" in "conn(s1,p2)") e compila una tabella di conversione interna (fact_by_value).


Il traduttore di Fast Downward, quando compila il PDDL, tende a eliminare i predicati statici (come la lista dei nodi della rete). Per evitare di dover scrivere a mano i nodi nell'ASP, clingo_init analizza tutti i fluenti geometrici (es. conn(s1,p2)), ne "stringe" gli argomenti ed estrae i nomi delle sottostazioni. In automatico genera una stringa di fatti ASP del tipo: node(s1). node(p2). ....

Lettura degli Encoding da Disco:
Legge le variabili d'ambiente del sistema operativo:

Va a prendere l'indirizzo memorizzato in DNTP_EVAL e carica in memoria (nella stringa eval_lp_text) tutto il codice ASP scritto per risolvere gli assiomi

Se presente, fa la stessa cosa con DNTP_FACTS, caricando i fatti statici specifici dell'istanza (ad esempio le definizioni di primary, secondary e l'ordine le).

Quindi lascia in memoria l'encoding ASP completo, la lista dei nodi del grafo e la mappa degli assiomi che Clingo dovrà comandare.

2. clingo_override (Questo metodo invece viene eseguito ogni ogni stato)
Questa funzione viene chiamata in coda al metodo evaluate(state). Ogni volta che Fast Downward genera o esplora un nuovo stato intermedio.


Traduce lo Stato Corrente in Fatti ASP:
La funzione prende il vettore numerico dello stato attuale di Fast Downward. Per ogni variabile attiva in quel momento, va a guardare la tabella fact_by_value e genera una stringa di testo contenente i fatti ASP reali. Ad esempio, se nello stato l'interruttore tra s1 e s2 è chiuso, genererà la stringa "conn(s1,s2). close(s1,s2).".

Controllo della Cache:
Prima di fare calcoli, unisce tutti i fatti correnti in una stringa-chiave, Cerca questa chiave dentro una tabella di memoria (eval_cache).

Cache-Hit: Se questo identico stato elettrico è già stato valutato da Clingo in un passo precedente della ricerca, la funzione prende il verdetto direttamente dalla RAM e salta l'esecuzione di Clingo.

Cache-Miss: Se lo stato è completamente nuovo, invece invoca clingo

Invocazione di Clingo:
Se lo stato non era in cache, il bridge crea un'istanza per ASP: Clingo::Control ctl{}.

Unisce l'encoding delle regole + i fatti statici dell'istanza + i nodi scoperti + i fatti dello stato corrente.

Grounding e Solving: Dice a Clingo di fare il grounding e il solving. Poiché Clingo riceve solo gli archi reali di quel preciso stato, il grounding è computazionalmente leggero.

Lettura dei Modelli Stabili (#show): Se Clingo trova un modello valido, legge gli atomi mostrati tramite la direttiva #show. Se l'atomo rad o l'atomo restore sono presenti nel modello, significa che lo stato è elettricamente valido. Questi nomi vengono salvati in un insieme temporaneo (got).



Che il risultato arrivi dalla cache o da un calcolo fresco di Clingo, la funzione prende la mappa gate_var e va a sovrascrivere direttamente il vettore di stato di Fast Downward:

Se l'atomo restore è presente nel verdetto di Clingo, lo stato di Fast Downward in quella posizione viene forzato a 0 (Vero per il pianificatore).

Se l'atomo è assente, viene forzato a 1 (Falso per il pianificatore).

Come fa questo a potare il grafo di ricerca?
Il C++ non scarta direttamente lo stato. Tuttavia, forzando a 1 (Falso) la variabile derivata restore(), tutte le azioni del PDDL che richiedevano restore come precondizione non saranno più applicabili, e se il goal del problema richiede restore, lo stato diventerà un vicolo cieco (dead-end). Fast Downward, vedendo che da lì non può più raggiungere l'obiettivo, scarterà lo stato e cambierà strada nel grafo di ricerca.
