# Main target
java: javacp javaalgorithms javagraph javalp

# Clean target
clean_java:
	-$(DEL) $(LIBPREFIX)jni*.$(JNILIBEXT)
	-$(DEL) lib$S*.jar
	-$(DEL) gen$Salgorithms$S*java_wrap*
	-$(DEL) gen$Scom$Sgoogle$Sortools$Sconstraintsolver$S*.java
	-$(DEL) gen$Scom$Sgoogle$Sortools$Sgraph$S*.java
	-$(DEL) gen$Scom$Sgoogle$Sortools$Sknapsacksolver$S*.java
	-$(DEL) gen$Scom$Sgoogle$Sortools$Slinearsolver$S*.java
	-$(DEL) gen$Sconstraint_solver$S*java_wrap*
	-$(DEL) gen$Sgraph$S*java_wrap*
	-$(DEL) gen$Slinear_solver$S*java_wrap*
	-$(DEL) objs$Scom$Sgoogle$Sortools$Sconstraintsolver$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Sgraph$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Sknapsacksolver$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Slinearsolver$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Sconstraintsolver$Ssamples$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Sgraph$Ssamples$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Sknapsacksolver$Ssamples$S*.class
	-$(DEL) objs$Scom$Sgoogle$Sortools$Slinearsolver$Ssamples$S*.class
	-$(DEL) objs$S*java_wrap.$O

# ---------- Java support using SWIG ----------

# javacp

javacp: lib/com.google.ortools.constraintsolver.jar $(LIBPREFIX)jniconstraintsolver.$(JNILIBEXT)
gen/constraint_solver/constraint_solver_java_wrap.cc: constraint_solver/constraint_solver.swig base/base.swig util/data.swig constraint_solver/constraint_solver.h
	$(SWIG_BINARY) -c++ -java -o gen$Sconstraint_solver$Sconstraint_solver_java_wrap.cc -package com.google.ortools.constraintsolver -outdir gen$Scom$Sgoogle$Sortools$Sconstraintsolver constraint_solver$Sconstraint_solver.swig

objs/constraint_solver_java_wrap.$O: gen/constraint_solver/constraint_solver_java_wrap.cc
	$(CCC) $(JNIFLAGS) $(JAVA_INC) -c gen/constraint_solver/constraint_solver_java_wrap.cc $(OBJOUT)objs/constraint_solver_java_wrap.$O

lib/com.google.ortools.constraintsolver.jar: gen/constraint_solver/constraint_solver_java_wrap.cc
	$(JAVAC_BIN) -d objs com$Sgoogle$Sortools$Sconstraintsolver$S*.java gen$Scom$Sgoogle$Sortools$Sconstraintsolver$S*.java
	$(JAR_BIN) cf lib$Scom.google.ortools.constraintsolver.jar -C objs com$Sgoogle$Sortools$Sconstraintsolver

$(LIBPREFIX)jniconstraintsolver.$(JNILIBEXT): objs/constraint_solver_java_wrap.$O $(CP_DEPS)
	$(LD) $(LDOUT)$(LIBPREFIX)jniconstraintsolver.$(JNILIBEXT) objs/constraint_solver_java_wrap.$O $(CP_LNK) $(LDFLAGS)

# Java CP Examples

compile_RabbitsPheasants: objs/com/google/ortools/constraintsolver/samples/RabbitsPheasants.class

objs/com/google/ortools/constraintsolver/samples/RabbitsPheasants.class: javacp com/google/ortools/constraintsolver/samples/RabbitsPheasants.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com$Sgoogle$Sortools$Sconstraintsolver$Ssamples$SRabbitsPheasants.java

run_RabbitsPheasants: compile_RabbitsPheasants
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.RabbitsPheasants

compile_GolombRuler: objs/com/google/ortools/constraintsolver/samples/GolombRuler.class

objs/com/google/ortools/constraintsolver/samples/GolombRuler.class: javacp com/google/ortools/constraintsolver/samples/GolombRuler.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/GolombRuler.java

run_GolombRuler: compile_GolombRuler
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.GolombRuler

compile_Partition: objs/com/google/ortools/constraintsolver/samples/Partition.class

objs/com/google/ortools/constraintsolver/samples/Partition.class: javacp com/google/ortools/constraintsolver/samples/Partition.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Partition.java

run_Partition: compile_Partition
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Partition

compile_SendMoreMoney: objs/com/google/ortools/constraintsolver/samples/SendMoreMoney.class

objs/com/google/ortools/constraintsolver/samples/SendMoreMoney.class: javacp com/google/ortools/constraintsolver/samples/SendMoreMoney.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/SendMoreMoney.java

run_SendMoreMoney: compile_SendMoreMoney
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.SendMoreMoney

compile_SendMoreMoney2: objs/com/google/ortools/constraintsolver/samples/SendMoreMoney2.class

objs/com/google/ortools/constraintsolver/samples/SendMoreMoney2.class: javacp com/google/ortools/constraintsolver/samples/SendMoreMoney2.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/SendMoreMoney2.java

run_SendMoreMoney2: compile_SendMoreMoney2
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.SendMoreMoney2

compile_LeastDiff: objs/com/google/ortools/constraintsolver/samples/LeastDiff.class

objs/com/google/ortools/constraintsolver/samples/LeastDiff.class: javacp com/google/ortools/constraintsolver/samples/LeastDiff.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/LeastDiff.java

run_LeastDiff: compile_LeastDiff
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.LeastDiff

compile_MagicSquare: objs/com/google/ortools/constraintsolver/samples/MagicSquare.class

objs/com/google/ortools/constraintsolver/samples/MagicSquare.class: javacp com/google/ortools/constraintsolver/samples/MagicSquare.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/MagicSquare.java

run_MagicSquare: compile_MagicSquare
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.MagicSquare

compile_NQueens: objs/com/google/ortools/constraintsolver/samples/NQueens.class

objs/com/google/ortools/constraintsolver/samples/NQueens.class: javacp com/google/ortools/constraintsolver/samples/NQueens.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/NQueens.java

run_NQueens: compile_NQueens
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.NQueens

compile_NQueens2: objs/com/google/ortools/constraintsolver/samples/NQueens2.class

objs/com/google/ortools/constraintsolver/samples/NQueens2.class: javacp com/google/ortools/constraintsolver/samples/NQueens2.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/NQueens2.java

run_NQueens2: compile_NQueens2
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.NQueens2


compile_AllDifferentExcept0: objs/com/google/ortools/constraintsolver/samples/AllDifferentExcept0.class

objs/com/google/ortools/constraintsolver/samples/AllDifferentExcept0.class: javacp com/google/ortools/constraintsolver/samples/AllDifferentExcept0.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/AllDifferentExcept0.java

run_AllDifferentExcept0: compile_AllDifferentExcept0
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.AllDifferentExcept0


compile_Diet: objs/com/google/ortools/constraintsolver/samples/Diet.class

objs/com/google/ortools/constraintsolver/samples/Diet.class: javacp com/google/ortools/constraintsolver/samples/Diet.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Diet.java

run_Diet: compile_Diet
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Diet


compile_Map: objs/com/google/ortools/constraintsolver/samples/Map.class

objs/com/google/ortools/constraintsolver/samples/Map.class: javacp com/google/ortools/constraintsolver/samples/Map.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Map.java

run_Map: compile_Map
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Map


compile_Map2: objs/com/google/ortools/constraintsolver/samples/Map2.class

objs/com/google/ortools/constraintsolver/samples/Map2.class: javacp com/google/ortools/constraintsolver/samples/Map2.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Map2.java

run_Map2: compile_Map2
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Map2


compile_Minesweeper: objs/com/google/ortools/constraintsolver/samples/Minesweeper.class

objs/com/google/ortools/constraintsolver/samples/Minesweeper.class: javacp com/google/ortools/constraintsolver/samples/Minesweeper.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Minesweeper.java

run_Minesweeper: compile_Minesweeper
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Minesweeper


compile_QuasigroupCompletion: objs/com/google/ortools/constraintsolver/samples/QuasigroupCompletion.class

objs/com/google/ortools/constraintsolver/samples/QuasigroupCompletion.class: javacp com/google/ortools/constraintsolver/samples/QuasigroupCompletion.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/QuasigroupCompletion.java

run_QuasigroupCompletion: compile_QuasigroupCompletion
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.QuasigroupCompletion


compile_SendMostMoney: objs/com/google/ortools/constraintsolver/samples/SendMostMoney.class

objs/com/google/ortools/constraintsolver/samples/SendMostMoney.class: javacp com/google/ortools/constraintsolver/samples/SendMostMoney.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/SendMostMoney.java

run_SendMostMoney: compile_SendMostMoney
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.SendMostMoney


compile_Seseman: objs/com/google/ortools/constraintsolver/samples/Seseman.class

objs/com/google/ortools/constraintsolver/samples/Seseman.class: javacp com/google/ortools/constraintsolver/samples/Seseman.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Seseman.java

run_Seseman: compile_Seseman
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Seseman


compile_Sudoku: objs/com/google/ortools/constraintsolver/samples/Sudoku.class

objs/com/google/ortools/constraintsolver/samples/Sudoku.class: javacp com/google/ortools/constraintsolver/samples/Sudoku.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Sudoku.java

run_Sudoku: compile_Sudoku
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Sudoku


compile_Xkcd: objs/com/google/ortools/constraintsolver/samples/Xkcd.class

objs/com/google/ortools/constraintsolver/samples/Xkcd.class: javacp com/google/ortools/constraintsolver/samples/Xkcd.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Xkcd.java

run_Xkcd: compile_Xkcd
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Xkcd


compile_SurvoPuzzle: objs/com/google/ortools/constraintsolver/samples/SurvoPuzzle.class

objs/com/google/ortools/constraintsolver/samples/SurvoPuzzle.class: javacp com/google/ortools/constraintsolver/samples/SurvoPuzzle.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/SurvoPuzzle.java

run_SurvoPuzzle: compile_SurvoPuzzle
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.SurvoPuzzle


compile_Circuit: objs/com/google/ortools/constraintsolver/samples/Circuit.class

objs/com/google/ortools/constraintsolver/samples/Circuit.class: javacp com/google/ortools/constraintsolver/samples/Circuit.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/Circuit.java

run_Circuit: compile_Circuit
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.Circuit


compile_CoinsGrid: objs/com/google/ortools/constraintsolver/samples/CoinsGrid.class

objs/com/google/ortools/constraintsolver/samples/CoinsGrid.class: javacp com/google/ortools/constraintsolver/samples/CoinsGrid.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/CoinsGrid.java

run_CoinsGrid: compile_CoinsGrid
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.CoinsGrid

# javaalgorithms

javaalgorithms: lib/com.google.ortools.knapsacksolver.jar $(LIBPREFIX)jniknapsacksolver.$(JNILIBEXT)

gen/algorithms/knapsack_solver_java_wrap.cc: algorithms/knapsack_solver.swig base/base.swig util/data.swig algorithms/knapsack_solver.h
	$(SWIG_BINARY) -c++ -java -o gen/algorithms/knapsack_solver_java_wrap.cc -package com.google.ortools.knapsacksolver -outdir gen/com/google/ortools/knapsacksolver algorithms/knapsack_solver.swig

objs/knapsack_solver_java_wrap.$O: gen/algorithms/knapsack_solver_java_wrap.cc
	$(CCC) $(JNIFLAGS) $(JAVA_INC) -c gen/algorithms/knapsack_solver_java_wrap.cc $(OBJOUT)objs/knapsack_solver_java_wrap.$O

lib/com.google.ortools.knapsacksolver.jar: gen/algorithms/knapsack_solver_java_wrap.cc
	$(JAVAC_BIN) -d objs gen$Scom$Sgoogle$Sortools$Sknapsacksolver$S*.java
	$(JAR_BIN) cf lib$Scom.google.ortools.knapsacksolver.jar -C objs com$Sgoogle$Sortools$Sknapsacksolver

$(LIBPREFIX)jniknapsacksolver.$(JNILIBEXT): objs/knapsack_solver_java_wrap.$O $(ALGORITHMS_DEPS)
	$(LD) $(LDOUT)$(LIBPREFIX)jniknapsacksolver.$(JNILIBEXT) objs/knapsack_solver_java_wrap.$O $(ALGORITHMS_LNK) $(LDFLAGS)

# Java Algorithms Examples

compile_Knapsack: objs/com/google/ortools/knapsacksolver/samples/Knapsack.class

objs/com/google/ortools/knapsacksolver/samples/Knapsack.class: javaalgorithms com/google/ortools/knapsacksolver/samples/Knapsack.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.knapsacksolver.jar com/google/ortools/knapsacksolver/samples/Knapsack.java

run_Knapsack: compile_Knapsack
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.knapsacksolver.jar com.google.ortools.knapsacksolver.samples.Knapsack

# javagraph

javagraph: lib/com.google.ortools.graph.jar $(LIBPREFIX)jnigraph.$(JNILIBEXT)

gen/graph/graph_java_wrap.cc: graph/graph.swig base/base.swig util/data.swig graph/max_flow.h graph/min_cost_flow.h graph/linear_assignment.h
	$(SWIG_BINARY) -c++ -java -o gen/graph/graph_java_wrap.cc -package com.google.ortools.graph -outdir gen/com/google/ortools/graph graph/graph.swig

objs/graph_java_wrap.$O: gen/graph/graph_java_wrap.cc
	$(CCC) $(JNIFLAGS) $(JAVA_INC) -c gen/graph/graph_java_wrap.cc $(OBJOUT)objs/graph_java_wrap.$O

lib/com.google.ortools.graph.jar: gen/graph/graph_java_wrap.cc
	$(JAVAC_BIN) -d objs gen$Scom$Sgoogle$Sortools$Sgraph$S*.java
	$(JAR_BIN) cf lib$Scom.google.ortools.graph.jar -C objs com$Sgoogle$Sortools$Sgraph

$(LIBPREFIX)jnigraph.$(JNILIBEXT): objs/graph_java_wrap.$O $(GRAPH_DEPS)
	$(LD) $(LDOUT)$(LIBPREFIX)jnigraph.$(JNILIBEXT) objs/graph_java_wrap.$O $(GRAPH_LNK) $(LDFLAGS)

# Java Algorithms Examples

compile_FlowExample: objs/com/google/ortools/graph/samples/FlowExample.class

objs/com/google/ortools/graph/samples/FlowExample.class: javagraph com/google/ortools/graph/samples/FlowExample.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.graph.jar com/google/ortools/graph/samples/FlowExample.java

run_FlowExample: compile_FlowExample javagraph
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.graph.jar com.google.ortools.graph.samples.FlowExample

compile_LinearAssignmentAPI: objs/com/google/ortools/graph/samples/LinearAssignmentAPI.class

objs/com/google/ortools/graph/samples/LinearAssignmentAPI.class: javagraph com/google/ortools/graph/samples/LinearAssignmentAPI.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.graph.jar com/google/ortools/graph/samples/LinearAssignmentAPI.java

run_LinearAssignmentAPI: compile_LinearAssignmentAPI javagraph
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.graph.jar com.google.ortools.graph.samples.LinearAssignmentAPI

# javalp

javalp: lib/com.google.ortools.linearsolver.jar $(LIBPREFIX)jnilinearsolver.$(JNILIBEXT)

gen/linear_solver/linear_solver_java_wrap.cc: linear_solver/linear_solver.swig base/base.swig util/data.swig linear_solver/linear_solver.h gen/linear_solver/linear_solver.pb.h
	$(SWIG_BINARY) $(SWIG_INC) -c++ -java -o gen$Slinear_solver$Slinear_solver_java_wrap.cc -package com.google.ortools.linearsolver -outdir gen$Scom$Sgoogle$Sortools$Slinearsolver linear_solver$Slinear_solver.swig

objs/linear_solver_java_wrap.$O: gen/linear_solver/linear_solver_java_wrap.cc
	$(CCC) $(JNIFLAGS) $(JAVA_INC) -c gen/linear_solver/linear_solver_java_wrap.cc $(OBJOUT)objs/linear_solver_java_wrap.$O

lib/com.google.ortools.linearsolver.jar: gen/linear_solver/linear_solver_java_wrap.cc
	$(JAVAC_BIN) -d objs gen$Scom$Sgoogle$Sortools$Slinearsolver$S*.java
	$(JAR_BIN) cf lib$Scom.google.ortools.linearsolver.jar -C objs com$Sgoogle$Sortools$Slinearsolver

$(LIBPREFIX)jnilinearsolver.$(JNILIBEXT): objs/linear_solver_java_wrap.$O $(LP_DEPS)
	$(LD) $(LDOUT)$(LIBPREFIX)jnilinearsolver.$(JNILIBEXT) objs/linear_solver_java_wrap.$O $(LP_LNK) $(LDFLAGS)

# Java Linear Programming Examples

compile_LinearProgramming: objs/com/google/ortools/linearsolver/samples/LinearProgramming.class

objs/com/google/ortools/linearsolver/samples/LinearProgramming.class: javalp com/google/ortools/linearsolver/samples/LinearProgramming.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.linearsolver.jar com/google/ortools/linearsolver/samples/LinearProgramming.java

run_LinearProgramming: compile_LinearProgramming
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.linearsolver.jar com.google.ortools.linearsolver.samples.LinearProgramming

compile_IntegerProgramming: objs/com/google/ortools/linearsolver/samples/IntegerProgramming.class

objs/com/google/ortools/linearsolver/samples/IntegerProgramming.class: javalp com/google/ortools/linearsolver/samples/IntegerProgramming.java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.linearsolver.jar com/google/ortools/linearsolver/samples/IntegerProgramming.java

run_IntegerProgramming: compile_IntegerProgramming
	$(JAVA_BIN) -Xss2048k -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.linearsolver.jar com.google.ortools.linearsolver.samples.IntegerProgramming

# Compile and Run CP java example:

objs/com/google/ortools/constraintsolver/samples/$(EX).class: javacp com/google/ortools/constraintsolver/samples/$(EX).java
	$(JAVAC_BIN) -d objs -cp lib$Scom.google.ortools.constraintsolver.jar com/google/ortools/constraintsolver/samples/$(EX).java

cjava: objs/com/google/ortools/constraintsolver/samples/$(EX).class com.google.ortools.constraintsolver.jar

rjava: objs/com/google/ortools/constraintsolver/samples/$(EX).class $(LIBPREFIX)jniconstraintsolver.$(JNILIBEXT) com.google.ortools.constraintsolver.jar
	$(JAVA_BIN) -Djava.library.path=$(TOP)$Slib -cp $(TOP)$Sobjs$(CPSEP)$(TOP)$Slib$Scom.google.ortools.constraintsolver.jar com.google.ortools.constraintsolver.samples.$(EX)

# Build stand-alone archive file for redistribution.

java_archive: java
	-$(DELREC) temp
	$(MKDIR) temp
	$(MKDIR) temp$Sor-tools.$(PLATFORM)
	$(COPY) *.jar temp$Sor-tools.$(PLATFORM)
	$(COPY) $(LIBPREFIX)jni*.$(JNILIBEXT) temp$Sor-tools.$(PLATFORM)
ifeq ("$(SYSTEM)","win")
	tools\mkdir temp\or-tools.$(PLATFORM)\com
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\constraintsolver
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\constraintsolver\samples
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\linearsolver
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\linearsolver\samples
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\graph
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\graph\samples
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\knapsacksolver
	tools\mkdir temp\or-tools.$(PLATFORM)\com\google\ortools\knapsacksolver\samples
	tools\mkdir temp\or-tools.$(PLATFORM)\data
	tools\mkdir temp\or-tools.$(PLATFORM)\data\discrete_tomography
	tools\mkdir temp\or-tools.$(PLATFORM)\data\fill_a_pix
	tools\mkdir temp\or-tools.$(PLATFORM)\data\minesweeper
	tools\mkdir temp\or-tools.$(PLATFORM)\data\rogo
	tools\mkdir temp\or-tools.$(PLATFORM)\data\survo_puzzle
	tools\mkdir temp\or-tools.$(PLATFORM)\data\quasigroup_completion
	copy data\discrete_tomography\* temp\or-tools.$(PLATFORM)\data\discrete_tomography
	copy data\fill_a_pix\* temp\or-tools.$(PLATFORM)\data\fill_a_pix
	copy data\minesweeper\* temp\or-tools.$(PLATFORM)\data\minesweeper
	copy data\rogo\* temp\or-tools.$(PLATFORM)\data\rogo
	copy data\survo_puzzle\* temp\or-tools.$(PLATFORM)\data\survo_puzzle
	copy data\quasigroup_completion\* temp\or-tools.$(PLATFORM)\data\quasigroup_completion
	copy com\google\ortools\constraintsolver\samples\*.java temp\or-tools.$(PLATFORM)\com\google\ortools\constraintsolver\samples
	copy com\google\ortools\linearsolver\samples\*.java temp\or-tools.$(PLATFORM)\com\google\ortools\linearsolver\samples
	copy com\google\ortools\graph\samples\*.java temp\or-tools.$(PLATFORM)\com\google\ortools\graph\samples
	copy com\google\ortools\knapsacksolver\samples\*.java temp\or-tools.$(PLATFORM)\com\google\ortools\knapsacksolver\samples
	cd temp$Sor-tools.$(PLATFORM) && tar -C ..$S.. -c -v com | tar -x -v -m --exclude=*.cs --exclude=*svn*
	cd temp && ..$Stools$Szip.exe -r ..$SGoogle.OrTools.java.$(PLATFORM).$(SVNVERSION).zip or-tools.$(PLATFORM)
else
	cd temp$Sor-tools.$(PLATFORM) && tar -C ..$S.. -c -v com | tar -x -v -m --exclude=\*.cs --exclude=\*svn\*
	cd temp && tar cvzf ..$SGoogle.OrTools.java.$(PLATFORM).$(SVNVERSION).tar.gz or-tools.$(PLATFORM)
endif
	-$(DELREC) temp

