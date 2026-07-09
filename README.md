# Fast Downward In-Process ASP Axiom Evaluator (First Architecture)

## Description
This project is a modified version of Fast Downward in which PDDL axioms (derived predicates, declared with `:derived`) are no longer evaluated internally by the planner, but delegated to an Answer Set Programming (ASP) solver (Clingo) connected directly in-process into the search engine. The evaluation happens state by state, at the exact point where Fast Downward's native `AxiomEvaluator` would otherwise compute the derived predicates.

The case study is the **Distribution Network Transition Problem (DNTP)**, the reconfiguration of electrical distribution networks, where one of the axioms, the *N-1 restoration* check performed after an edge falls, grounds combinatorially and drives Fast Downward into memory-out on large instances, before the search even begins.

### Key Capabilities
* **Axiom Removal, Not Deletion:** Axioms cannot simply be deleted from the PDDL model, since actions and the goal reference them. Instead, each axiom is emptied into a trivial 0-ary derived predicate, a *gate variable*, that Fast Downward still recognizes and propagates, but whose actual truth value is supplied from the outside by the ASP verdict.
* **In-Process State Evaluation:** For every state generated during the search, the bridge serializes the state's true atoms into ASP facts, adds the static facts of the instance (object types, canonical order), and invokes an in-process Clingo solver directly from the planner's C++ code, no external process spawning.
* **State Caching and $O(1)$ Pruning:** The serialized state is hashed into a deterministic cache key. Because a structural violation is permanent (a state that violates the constraints will always violate them), both SAT and UNSAT verdicts are memoized, turning repeated topologically-identical states, frequent due to action commutativity, into $O(1)$ cache hits instead of new solver calls.
* **Domain-Free Bridge:** Fast Downward and the bridge code know nothing about the specific domain. The entire domain logic lives in the replaceable ASP encoding (`.lp` file), which can be swapped to re-target the system to a different domain or notion of "valid state" without recompiling the planner.

## How It Works
The integration is implemented at the point where Fast Downward would normally evaluate its own axioms:

1. **Domain preparation:** the original PDDL axioms are emptied into trivial 0-ary derived gates (e.g. `(:derived (RESTORE) (and ))`), producing a lightweight *bridge domain* that Fast Downward can still parse and propagate normally.
2. **Initialization (`clingo_init`):** once, at task construction, the gate predicates are identified, and the ASP encoding plus the static instance facts are read.
3. **Search time (`clingo_override`):** at every generated state, the true atoms of the state are translated into ASP facts through a pre-computed lookup table, merged with the static facts, and handed to an in-process Clingo solver. If the combined program is satisfiable, all gates are set to true; otherwise, they are set to false and the state becomes a permanent dead-end, pruned by the search.

The bridge code lives in `FastDownward/src/search/axioms.cc`, in the `clingo_init` and `clingo_override` methods.

## Before You Start

### Requirements
* **Operating System:** Debian/Ubuntu based
* **ASP Solver:** Clingo 5.x
* **Build tools:** g++, cmake, make, Python 3

Clingo must be **compiled from source**, not installed via `conda` or `pip`, since the planner links directly against `libclingo`.

### 1. Compile Clingo
Choose the install path you prefer via the `CMAKE_INSTALL_PREFIX` flag.
```bash
sudo apt install build-essential cmake git

git clone --recursive https://github.com/potassco/clingo.git
cd clingo
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCLINGO_BUILD_SHARED=ON \
      -DCMAKE_INSTALL_PREFIX="$HOME/clingo-system"
cmake --build build -j
cmake --install build
cd ..
```

### 2. Configure the Paths
At the root of the repo, edit `config.env` with the paths to your Clingo installation:
```bash
CLINGO_LIB=/home/XXX/clingo-system/lib
CLINGO_CMAKE=/home/XXX/clingo-system/lib/cmake/Clingo
```

### 3. Build Fast Downward
```bash
cd FastDownward
CLINGO_DIR=/home/XXX/clingo-system/lib/cmake/Clingo ./build.py release
cd ..
```

## Usage
All runs go through the `dntp_run` script.

### Basic Examples
```bash
./dntp_run --real -all            # all real instances, from P06 to P150
./dntp_run --real P13             # only P13
./dntp_run --N -all               # all synthetic instances
./dntp_run --N N_8                # all synthetic instances with 8 nodes
./dntp_run -l                     # list available instances
./dntp_run -h                     # help
```

### Choosing Search Algorithm, Encoding and Timeout
```bash
./dntp_run --real -all --search astar   # search algorithm
./dntp_run --N N_22 --to 120            # 120s timeout
```

**Available search algorithms:** `ff` (default), `eager_ff`, `eager_pref`, `lama`, `astar`, `astar_ff`, `wastar`, `blind`.

### Output
Each run prints a summary table (instance, plan length, evaluated states, time, outcome), saves a CSV in `Plans/` with `N` and `alpha` extracted from the instance name, and writes the found plan to `Plans/<instance>.plan`.

## Plan Validation
Any suitable validator can be used. We used **VAL**: to validate a plan, pass the original (full, non-emptied) domain, the original problem instance, and the plan generated by this architecture.

## Limitations
* Only tested and supported on **Ubuntu 22.04** with **Clingo 5.x**; other platforms/versions are untested.
* The cost of the axioms does not disappear, it moves from translation time (combinatorial grounding) to search time (one Clingo call per generated state). The state cache mitigates this, but per-call solver overhead remains the dominant cost on search-intensive instances.
* Only 0-ary gate predicates are supported: an axiom is either globally true or false per state, there is no per-argument partial evaluation.
* No hybrid split between PDDL and ASP axioms, unlike the Second Architecture, all axioms delegated to this bridge must be moved to ASP; there is currently no way to keep cheap axioms in native PDDL. See Roadmap.

## Support
For bugs, questions, or feature requests, please use the repository's issue tracker.

## Roadmap
Future planned developments for this architecture include:
* **Hybrid Axiomatic Split:** Allowing lightweight axioms to remain natively in PDDL while only the expensive ones are delegated to ASP (already achieved in the Second Architecture — see `feat/fd_integration`).
* **Richer Reasoning Tasks:** The bridge currently evaluates Datalog-like, stratified ASP programs for satisfiability. Disjunctive rules, choice rules, and weak constraints/optimization are already usable in the encoding, but not yet exploited for anything beyond the SAT/UNSAT verdict.
* **CEGAR Integration:** Comparing this per-state evaluation approach against CEGAR-style (Counterexample-Guided Abstraction Refinement) axiom handling, which Fast Downward already supports as Cartesian abstraction refinement.
* **Upstream Contribution:** Submitting a Pull Request to the official Fast Downward repository, alongside the Second Architecture's native heuristic integration.

## Contributing
We are open to contributions! If you want to make changes or test new domains, keep the domain logic entirely inside the ASP encoding rather than the bridge code, so that the architecture remains domain-free. Please avoid introducing domain-specific assumptions into `clingo_init` or `clingo_override`.

## Authors and Acknowledgment
* **Lorenzo Pindilli** - Core Architect and Developer of the First Architecture.
* **Thomas Garrafa** - Asp encoding for the DNTP Domain.

## License
This code implementation is distributed under the GPLv3 license.

## Project Status
The integration is functional end-to-end and plans have been validated with VAL on the DNTP domain. The architecture solves the entire real benchmark (up to 152 nodes), including instances where the fully-grounded PDDL model fails by memory-out during grounding, and almost the entire synthetic benchmark (100/100 with LAMA-first, 97/100 with `ff`).
