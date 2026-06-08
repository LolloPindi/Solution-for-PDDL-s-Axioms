# Solution for PDDL's Axioms
This project is a modified version of Fast Downward where the axioms
of the PDDL (the ':derived') are no longer evaluated internally by the planner, but
from an ASP (Clingo) solver connected directly in the code. The evaluation
it happens state by state, during the search.

The domain we work on is DNTP, that is, network reconfiguration
distribution electrics.

## The basic idea

The reason this exists is grounding. In DNTP some axioms
(especially the one about restoring after an arc falls) explode in
grounding phase and on large instances send Fast Downward in memory-out first
still starting to look. The idea is to remove those axioms from the PDDL and make them
calculate in Clingo, once for each state visited.

Basically, for each state it generates, Fast Downward:

- takes the true atoms of the state and passes them to Clingo as facts (conn, close…)
- adds static instance data (node types, order, fixed edges)
- runs ASP encoding
- read the result and set the derived variables of the PDDL (rad, restore)

The actions and the goal have the derived ones as a precondition, so if Clingo
says that a constraint is not respected, that state becomes a dead end and the
planner discards it himself. Bridge knows nothing about domain: all the logic
is in ASP encoding, which can be changed without recompiling anything.

The link code is in 'FastDownward/src/search/axioms.cc', in
'clingo_init' and 'clingo_override' methods.

## Before you start

It serves Linux with the usual build tools (g++, cmake, make) and Python 3.

The important part is Clingo. Must be compiled from source, not installed with conda
or pip: those versions give linking problems with Fast Downward (we have
hit his head, it's a libstdc++ ABI problem). You need headers,
CMake library and package that match, and the only safe way is to compile it.

### 1. Compile Clingo

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



### 2. Arrange the routes

In the 'config.env' file, at the top of the repo, put the paths of your
Clingo installation:

```bash
CLINGO_LIB=/home/XXX/clingo-system/lib
CLINGO_CMAKE=/home/XXX/clingo-system/lib/cmake/Clingo
```



### 3. COMPILE FD

```bash
cd FastDownward
Clingo_DIR=/home/XXX/clingo-system/lib/cmake/Clingo ./build.py release
cd ..
```

When you see 'Built target downward' it's ready. The 'builds/' folder does not fit in the
repo (it's huge and tied to the path where you created it), so this step goes
redone every time you clone the project elsewhere.

## How to use it

Everything goes from 'dntp_run'. Some examples:

```bash
./dntp_run --real -all            # tutte le istanze reali, da P06 a P150
./dntp_run --real P13             # solo P13
./dntp_run --N -all               # tutte le sintetiche
./dntp_run --N N_8                # tutte le sintetiche da 8 nodi
./dntp_run -l                     # elenca le istanze disponibili
./dntp_run -h                     # aiuto
```

You can choose the search algorithm and encoding:

```bash
./dntp_run --real -all --search astar   # ricerca ottima, ma più lenta
./dntp_run --real P13 --enc rad         # solo radialità
./dntp_run --N N_22 --to 120            # timeout di 120s invece di 600
```

The available algorithms are `ff` (default), `eager_ff`, `eager_pref`, `lama`, `astar`, `astar_ff`, `wastar`, `blind`.
The encodings are `full` (default), `rad`, `rest_p`,
`rest_e`, `rad_rest_p`, You can also choose a lp file `.lp`.

Each run prints a table (instance, plan length, evaluated states,
time, outcome), saves a CSV in 'Plans/' with N and alpha extracted from the
instance name, and puts the found plans into 'Plans/<instance>.plan'.




