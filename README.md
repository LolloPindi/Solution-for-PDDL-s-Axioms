# Fast Downward In-Process ASP Heuristic Wrapper (Second Architecture)

## Description
This project introduces a seamless, modular integration of the Clingo Answer Set Programming (ASP) solver inside the Fast Downward automated planning framework at the build-system level. It implements a custom ASP-based heuristic wrapper that empowers users to establish a hybrid axiomatic framework, effectively splitting axiomatic definitions between PDDL and ASP.

While traditional PDDL planners suffer from a combinatorial explosion during the grounding of complex derived predicates, this architecture allows lightweight, tractable axioms to remain in the native PDDL model for high-performance internal evaluation. Meanwhile, computationally prohibitive axioms are offloaded to the embedded ASP solver.

### Key Capabilities
* **Automatic World Extraction:** To prevent Fast Downward's multi-valued SAS+ translation from aggressively pruning static propositions that the ASP program requires for global structural evaluation, the architecture intercepts object declarations and static facts during the initial Python translation phase. These are automatically serialized into temporary `.lp` files (`instance_types.lp` and `instance_static_facts.lp`).
* **In-Process State Evaluation:** At search time, the custom heuristic transparently unpacks the current state into dynamic ASP facts, merges them with the static knowledge base, and invokes an in-process `Clingo::Control` instance.
* **State Caching and $O(1)$ Pruning:** A deterministic cache key is generated from the state string to memoize solver verdicts. If a state is topologically valid (SAT), numerical estimation is delegated to an underlying base heuristic. If it violates global constraints (UNSAT), the state is recognized as a permanent dead-end and instantly pruned.
* **Plug-and-Play Clean Separation:** The system operates without custom PDDL annotations, auxiliary shell scripts, or messy environment variables. The ASP evaluation is seamlessly driven entirely via Fast Downward's standard command-line interface by supplying the `.lp` encoding file as a native heuristic parameter.

## How It Works
The integration lives at the build-system level rather than as a bolt-on script:

1. **Build time:** `build.py` reads the `CLINGO_DIR` environment variable and passes it through to Fast Downward's CMake configuration, so the compiled planner links directly against `libclingo`. This is why `CLINGO_DIR` must point at Clingo's CMake package directory (`.../lib/cmake/Clingo`) rather than the install root.
2. **Translation time:** during Fast Downward's Python translation phase, object declarations and static facts that would otherwise be discarded by the SAS+ grounder are captured and written out as `.lp` facts.
3. **Search time:** each time the heuristic is evaluated on a state, the current dynamic facts are combined with the static `.lp` knowledge base and handed to an in-process `Clingo::Control` instance. The SAT/UNSAT verdict is cached by state key; SAT states fall through to the `base_heuristic` for a numeric estimate, UNSAT states are pruned outright.

### The `base_heuristic` parameter
`asp(base_heuristic, "path/to/encoding.lp")` wraps any native Fast Downward heuristic. `base_heuristic` is **required** — it supplies the numeric estimate for states that pass the ASP satisfiability check. Any heuristic accepted elsewhere on the Fast Downward command line (`ff()`, `blind()`, `lmcut()`, etc.) is valid here; the ASP layer only ever adds a SAT/UNSAT filter on top of it, it doesn't replace the numeric estimation itself.

## Installation

### Requirements
* **Operating System:** Debian/Ubuntu based
* **ASP Solver:** Clingo 5.x

### Compilation & Build Setup
The Second Architecture elevates integration to the build-system level, natively extending Fast Downward's compilation scripts.

#### 1. Preliminary Setup: Install and Compile Clingo
Choose the path you desire via changing the flag `CMAKE_INSTALL_PREFIX`

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

#### 2. Add the Clingo Environment Variable
Define the environment variable `CLINGO_DIR`

```bash
export CLINGO_DIR="$HOME/clingo-system/lib/cmake/Clingo"
```

#### 3. Build

Move into the FastDownward folder, then launch the file `build.py` with the proper configuration

```bash
./build.py asp_debug
```

## Usage
The ASP heuristic is encapsulated strictly as a standard heuristic evaluator with the console keyword `asp` and the signature `asp(base_heuristic, "path/to/encoding.lp")`. It can be combined with any compatible search algorithm and any other heuristics supported natively by the planner.

### Example 1: Optimal Search ($A^*$)
```bash
./fast-downward.py --build asp_debug domain.pddl problem.pddl \
  --search 'astar (asp (ff(), "path/to/encoding.lp"))'
```

### Example 2: Satisficing Search (Lazy Greedy)
```bash
./fast-downward.py --build asp_debug domain.pddl problem.pddl \
  --search 'lazy_greedy ([asp(ff(), "path/to/encoding.lp")])'
```

### Example 3: Debugging Mode (Preserving Intermediate Artifacts)
During standard execution, the temporary `.lp` serialization files are automatically cleaned up upon termination. For advanced debugging, manual inspection, or incremental solver testing, you can append the `--keep-asp-files` flag to bypass the teardown phase and preserve the files:
```bash
./fast-downward.py --build asp_debug --keep-asp-files domain.pddl problem.pddl \
  --search 'astar (asp (blind(), "path/to/encoding.lp"))'
```

### Example 4: LAMA-First Integration
This shows how to inject the ASP evaluator into the LAMA-First configuration, working alongside preferred operators and the landmark heuristic (`hlm`):
```bash
./fast-downward.py --build asp_debug domain.pddl problem.pddl \
  --heuristic 'hlm=landmark_sum(lm_factory=lm_reasonable_orders_hps(lm_rhw()), transform=adapt_costs (one), pref=false)' \
  --heuristic 'hasp=asp(ff (transform=adapt_costs (one)), "path/to/encoding.lp")' \
  --search 'lazy_greedy ([hasp, hlm], preferred=[hasp,hlm], cost_type=one, reopen_closed=false)'
```

### Executing on real problems
The folders 'PDDL' and 'ASP' contain two problems that can be solved with the new architecture:
- dntp problem: handles the distribution network transition problem
- robot_simple: shows a simple problem where the axioms definition have been integrated in both ASP and PDDL files, enabling an hybrid axiomatic implementation

Here is an example: the problem P30 has been executed on an ASP file containing every axioms (full)

NOTE: for DNTP problems, use the `domain_dntp_noaxioms.pddl` domain file.

```bash
./fast-downward.py --build asp_debug ../PDDL/dntp/domain/domain_dntp_noaxioms.pddl ../PDDL/dntp/problem/P30.pddl   --search 'lazy_greedy([asp (ff(), "../ASP/dntp/full.lp")])'
```

## Limitations
* Only tested and supported on **Ubuntu 22.04** with **Clingo 5.x**; other platforms/versions are untested.
* The `.lp` encoding itself can use any valid Clingo construct — disjunctive rules, choice rules, weak constraints, and optimization statements are all accepted and solved normally by Clingo. The limitation is on the **wrapper's interface**: only the SAT/UNSAT verdict is extracted and fed back to the planner as a pruning signal. Any optimization value Clingo computes internally is not currently propagated as a numeric heuristic estimate — see Roadmap.
* No native `--alias` integration yet; the ASP heuristic must currently be wired in manually via `--heuristic`/`--search`.
* Per-state solver invocation, even when cached, adds overhead relative to pure PDDL evaluation — the trade-off is most favorable on domains where PDDL grounding would otherwise blow up.

## Support
For bugs, questions, or feature requests, please use the repository's issue tracker.

## Roadmap
Future planned developments for this architecture include:
* **Heuristic Aliases:** Natively integrating the ASP heuristic directly into complex Fast Downward built-in aliases (such as `--alias`).
* **Richer Reasoning Tasks:** Expanding the wrapper's interface beyond a binary SAT/UNSAT verdict, so that results from advanced ASP constructs already usable in the encoding — weak constraints and optimization statements in particular — can be propagated as a numeric signal into the heuristic estimate, rather than only being computed internally by Clingo and discarded.
* **CEGAR Integration:** Positioning and comparing this per-state approach within the broader landscape of automated planning techniques, specifically against CEGAR-style (Counterexample-Guided Abstraction Refinement) axiom methods.
* **Upstream Contribution:** Finalizing minor code adjustments to match the upstream core maintainers' standards and submitting an official Pull Request to the main Fast Downward repository.

## Contributing
We are open to contributions! If you want to make changes or test new domains, ensure that your additions strictly leverage Fast Downward's native `TypedFeature` plugin system to guarantee compile-time injection into the planner's global registry. Please make sure your contributions avoid introducing external environment variables or auxiliary shell scripts to maintain the architecture's self-contained nature.

## Authors and acknowledgment
* **Thomas Garrafa** - Core Architect and Developer of the Second Architecture.
* **Lorenzo Pindilli** - Testing and validating.

## License
This code implementation is distributed under the GPLv3 license.

## Project status
The integration is functional end-to-end and plans have been validated with VAL on the domains tested so far. Benchmark results (domains covered, overhead vs. baseline heuristics, memory savings on grounding-heavy instances) are not yet published — see Roadmap for planned upstream contribution and evaluation work.
