# Profiling with flamegraphs

## What's profiling/why profile?

- If you want code to run faster, you need to know which parts are slow
- Guesswork doesn't always get the right answer
- Profiling is analysing where the resources are being used in running code
  - Especially **CPU time**, but maybe memory and other things

## Wise sayings:

**Amdahl's Law:**
> "the overall performance improvement gained by optimizing a single part of a system is limited by the fraction of time that the improved part is actually used"

**Donald Knuth:**
> "premature optimization is the root of all evil"

## Profilers

### Strategy

- **Deterministic**
  - Record when certain things happen (e.g. enter/exit subroutines)
  - Using _instrumentation_ or _events_
  - Pro: accurately records everything that happens
  - Con: can slow things down (sometimes a lot)
- **Statistical**
  - Repeatedly ask "what's the status now?" and record the answers
  - Less intrusive, less likely to affect the timings it's trying to measure

### Types

- **System level**
  - Linux `perf`
  - MacOS `Instruments`(?)
  - May need privileged access 
    - (`sudo sysctl kernel.perf_event_paranoid=0`)
  - May not understand/report stack frames in a language-friendly way

- **Language-specific**
  - Java: [`HPROF`](https://docs.oracle.com/javase/8/docs/technotes/samples/hprof.html),
          [`async-profiler`](https://github.com/async-profiler/async-profiler)
  - Python: [`cProfile`](https://docs.python.org/3/library/profile.html),
            [`py-spy`](https://github.com/benfred/py-spy)
  - others ...
  - Not all profilers are equal!

### Output

For CPU profiling the output from the profiler is usually a list of
function names or stack traces with timings.

These can be hard to read.

Which is why you need...

## Flamegraphs!

[Flamegraphs](https://www.brendangregg.com/flamegraphs.html)
provide a visualisation of hierarchical data like stacktraces.
Invented by Brendan Gregg around 2013(?)
they exist in various forms:

- Original [FlameGraph](https://github.com/brendangregg/FlameGraph)
  github repository contains useful tools
- Some profilers output flamegraphs directly

Output is interactive SVG (Scalable Vector Graphics) - click on an
element to expand/contract it to the full page width.

Example outputs:
- STILTS matching:
  [before](https://www.star.bristol.ac.uk/mbt/flamegraphs/stilts-treeset.html)
  and
  [after](https://www.star.bristol.ac.uk/mbt/flamegraphs/stilts-hashset.html)
  a 2-line change to matching code
  ([a561d815](https://github.com/Starlink/starjava/commit/a561d815a),
   replace `TreeMap` with `HashMap`)

### Try it out!

Python example using [py-spy](https://github.com/benfred/py-spy):
- Install py-spy, one of the following might work:
  - MacOS: `brew install py-spy`
  - other: `pip install py-spy`
- Run `py-spy record` on a python program you want to profile
  - from the start:
    ```
    py-spy record --native -o pyspy.svg -- python program.py
    ```
  - attach to a running process:
    ```
    py-spy record -o pyspy.svg --pid 12345`
    ```
- (py-spy has some other nice tricks too like `py-spy top`)

Python example using
[`cProfile`](https://docs.python.org/3/library/profile.html):
- cProfile is included with python and it can produce text summaries
  or binary cprof files.
- You need [flameprof](https://pypi.org/project/flameprof/) to turn
  the cprof files into flamegraphs:
  ```
  pip install flameprof
  ```
- Run a python program with cProfile enabled:
  ```
  python -m cProfile -o program.cprof program.py 
  ```
- Convert the output to a flamegraph:
  ```
  flameprof program.cprof > cprof.svg
- (The flamegraphs don't seem to be interactive for me, but the docs
  suggest they should be)

Example using system logging tools:
- On Linux you can use `perf`, then pass the output to FlameGraph scripts
  - Clone the FlameGraph repo
    ```
    git clone https://github.com/brendangregg/FlameGraph
    ```
- Run your program with `perf record`
  ```
  perf record -F 99 -a -g --call-graph dwarf,32768 -- my-program

  ```
- Generate a flamegraph from the result:
  ```
  perf script \
     | FlameGraph//stackcollapse-perf.pl \
     | FlameGraph/flamegraph.pl > results/perf.svg

  ```
- I think you can do something similar on MacOS using `Instruments`
  (maybe [here](https://github.com/Kelvenbit/FlameGraphs-Instruments)
   or [here](https://carol-nichols.com/2015/12/09/rust-profiling-on-osx-cpu-time/)??)


### Other uses

- You can use flamegraphs for other things too, e.g.  memory usage,
  off-CPU time, special event categories (`perf` has lots of options).
- And here's a neat trick to see what's taking up space on your disk:
  ```
  git clone https://github.com/brendangregg/FlameGraph
  FlameGraph/files.pl ~ | FlameGraph/flamegraph.pl > files.svg
  ```



