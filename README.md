# Fast Downward In-Process ASP Axiom Evaluator (First Architecture)

## Description
This project is a modified version of Fast Downward in which PDDL axioms (derived predicates, declared with `:derived`) are no longer evaluated internally by the planner, but delegated to an Answer Set Programming (ASP) solver (Clingo) connected directly in-process into the search engine. The evaluation happens state by state, at the exact point where Fast Downward's native `AxiomEvaluator` would otherwise compute the derived predicates.

The case study is the **Distribution Network Transition Problem (DNTP)**, the reconfiguration of electrical distribution networks, where one of the axioms, the *N-1 restoration* check performed after an edge falls, grounds combinatorially and drives Fast Downward into memory-out on large instances, before the search even begins.

### Key Capabilities
* **Axiom Removal, Not Deletion:** Axioms cannot simply be deleted from the PDDL model, since actions and the goal reference them. Instead, each axiom is emptied into a trivial 0-ary derived predicate, a *gate variable*, that Fast Downward still recognizes and propagates, but whose actual truth value is supplied from the outside by the ASP verdict.
* **In-Process State Evaluation:** For every state generated during the search, the bridge serializes the state's true atoms into ASP facts, adds the static facts of the instance (object types, canonical order), and invokes an in-process Clingo solver directly from the planner's C++ code, no external process spawning.
* **State Caching and $O(1)$ Pruning:** The serialized state is hashed into a deterministic cache key. Because a structural violation is permanent (a state that violates the constraints will always violate them), both SAT and UNSAT verdicts are memoized, turning repeated topologically-identical states, frequent due to action commutativity, into $O(1)$ cache hits instead of new solver calls.
* **Domain-Free Bridge:** Fast Downward and the bridge code know nothing about the specific domain. The entire domain logic lives in the replaceable ASP encoding (`.lp` file), which can be swapped to re-target the system to a different domain or notion of "valid state" without recompiling the planner.
