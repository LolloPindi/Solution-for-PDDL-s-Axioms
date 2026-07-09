
# Solution for PDDL's Axioms

This repository contains two architectures for evaluating PDDL axioms via ASP (Clingo), integrated into Fast Downward. In both approaches, PDDL axioms (`:derived` predicates) are evaluated by an external ASP solver instead of being grounded internally by the planner, avoiding the combinatorial explosion that can occur on complex domains such as the Distribution Network Transition Problem (DNTP).

## Architectures

### Architecture 1 : In-Process Axiom Evaluator

ASP acts as a direct replacement for Fast Downward's internal axiom evaluator: PDDL axioms are emptied into gate predicates, and their truth value is supplied by Clingo at every generated state.

See branch: [asp-axiom-evaluator](../../tree/feat/asp-axiom-evaluator)

### Architecture 2 : Generic Heuristic Wrapper

ASP is integrated as a native Fast Downward heuristic, enabling a hybrid split where only the expensive axioms are delegated to Clingo, while lightweight ones remain in native PDDL.

See branch: [fd_integration](../../tree/feat/fd_integration)

---

See the individual branches for the full source code, ASP encodings, build instructions, and experimental results.

