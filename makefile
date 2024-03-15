# Makefile to build profiling inputs and outputs.
#
# In principle, 'make run' ought to generate various example flamegraphs
# in the results/ subdirectory.  It does on my machine.
# Other useful targets are 'build', 'clean' and 'veryclean'.
#
# It might not for you, if you don't have java and maybe some other
# things installed, but this at least serves as documentation of
# what commands need to be run.

STILTS = java -jar stilts.jar
MBT_WWW = https://www.star.bristol.ac.uk/mbt/
NROW = 1000000
MAXARCSEC = 10
T0 = t0-$(NROW).fits
T1 = t1-$(NROW).fits
T2 = t2-$(NROW).fits
PYSPY = py-spy
FLAMEPROF = flameprof
PYTHON = python3

TEST_DATA = $(T0) $(T1) $(T2)
STILTS_VERSIONS = stilts-3.2-1.jar stilts-3.2.jar stilts.jar

JPROFILER = libasyncProfiler.so

build: $(STILTS_VERSIONS) $(TEST_DATA) $(JPROFILER) \
       $(PYSPY) $(FLAMEPROF) FlameGraph results

run: build pyspy-profile cprofile hprof stilts-flamegraphs perf-profile

clean:
	rm -f stilts-3.2.hprof stilts-3.2-1.hprof
	rm -f stilts-3.2.html stilts-3.2-1.html
	rm -f match2-cprofile.cprof out.perf-folded perf.data perf.data.old
	rm -rf results

veryclean: clean
	rm -f $(STILTS_VERSIONS) $(TEST_DATA) SkyLib.class $(JPROFILER)
	rm -f stilts-hashset.jar stilts-treeset.jar
	rm -rf FlameGraph

results:
	mkdir -p results

$(PYSPY):
	@$(PYSPY) -V 2>&1 >/dev/null \
           || ( echo "Try pip install py-spy"; test -z 1 )

$(FLAMEPROF):
	@$(FLAMEPROF) -h 2>&1 >/dev/null \
           || ( echo "Try pip install flameprof"; test -z 1 )

FlameGraph:
	git clone https://github.com/brendangregg/FlameGraph

stilts.jar:
	curl -sLO $(MBT_WWW)/stilts/$@

stilts-3.2-1.jar:
	curl -sL $(MBT_WWW)/releases/stilts/v3.2-1/stilts.jar >$@

stilts-3.2.jar:
	curl -sL $(MBT_WWW)/releases/stilts/v3.2/stilts.jar >$@

SkyLib.class: SkyLib.java
	javac -classpath /mbt/starjava/lib/pal/pal.jar SkyLib.java

libasyncProfiler.so:
	rm -rf tmp
	( mkdir -p tmp; \
          cd tmp; \
          curl -OL https://github.com/async-profiler/async-profiler/releases/download/v3.0/async-profiler-3.0-linux-x64.tar.gz; \
          tar zxf async-profiler-3.0-linux-x64.tar.gz; \
          cp async-profiler-3.0-linux-x64/lib/$@ ../ )
	rm -rf tmp

$(T0): stilts.jar
	java -jar stilts.jar tpipe in=:skysim:$(NROW) cmd=progress out=$@

$(T1): stilts.jar $(T0)
	java -jar stilts.jar tpipe in=$(T0) \
           cmd=progress \
           cmd='select $$0%11>=2' \
           out=$@

$(T2): stilts.jar $(T0) SkyLib.class
	java -Djel.classes=SkyLib -classpath .:stilts.jar \
             uk.ac.starlink.ttools.Stilts \
           tpipe in=$(T0) \
           cmd='addcol -units deg ra0 ra' \
           cmd='addcol -units deg dec0 dec' \
           cmd="addcol pos1 randomShiftFlat(ra0,dec0,$(MAXARCSEC)/3600.)" \
           cmd='addcol -units deg -ucd "pos.eq.ra;meta.main" ra1 pos1[0]' \
           cmd='addcol -units deg -ucd "pos.eq.dec;meta.main" dec1 pos1[1]' \
           cmd='keepcols "ra1 dec1 ra0 dec0"' \
           cmd='select $$0%10>=2' \
           out=$@

JMATCHARGS = tmatch2 progress=none matcher=sky \
             in1=$(T1) in2=$(T2) values1='ra dec' values2='ra1 dec1' \
             params=10 find=all omode=count

tree-hash-profs: stilts-2e1e0fef.jar stilts-a561d815.jar
	ln -sf stilts-2e1e0fef.jar stilts-treeset.jar
	ln -sf stilts-a561d815.jar stilts-hashset.jar
	for version in -treeset -hashset; \
	do \
           flamefile=stilts$$version.html; \
           java -agentpath:./libasyncProfiler.so=start,event=cpu,file=$$flamefile \
                -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints \
                -jar stilts$$version.jar \
                -bench \
                $(JMATCHARGS); \
           echo " -> $$flamefile"; \
	   echo; \
        done

# Run sub-targets

stilts-flamegraphs: $(TEST_DATA) $(STILTS_VERSIONS) $(JPROFILER) \
                    results
	for version in -3.2 -3.2-1; \
        do \
           flamefile=results/stilts$$version.html; \
           java -agentpath:./libasyncProfiler.so=start,event=cpu,file=$$flamefile \
                -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints \
                -jar stilts$$version.jar \
                -bench \
                $(JMATCHARGS); \
           echo " -> $$flamefile"; \
	   echo; \
        done

hprof: build
	java -Xrunhprof:cpu=samples,depth=32,file=results/stilts.hprof \
             -jar stilts.jar -bench $(JMATCHARGS); \

cprofile: build
	$(PYTHON) -m cProfile -s tottime match2.py >results/match2-cprofile.txt
	$(PYTHON) -m cProfile -o match2-cprofile.cprof match2.py
	$(FLAMEPROF) match2-cprofile.cprof >results/match2-cprofile.svg

# Works nicely.  May require root on MacOS?
pyspy-profile: build $(PYSPY)
	time $(PYSPY) record --native -o results/match2-pyspy.svg -- \
             $(PYTHON) match2.py \
        || echo "sometimes fails, probably OK"
 
# May require sudo sysctl kernel.perf_event_paranoid=0
# Other OS equivalents are instruments (MacOS), Xperf.exe (Windows)
perf-profile: build
	perf record -F 99 -a -g --call-graph dwarf,32768 -- $(PYTHON) match2.py
	perf script \
             | FlameGraph//stackcollapse-perf.pl \
             | FlameGraph/flamegraph.pl > results/match2-perf.svg
	
