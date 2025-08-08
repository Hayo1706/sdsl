module sheetdsl::demo::Statemachine::Main
import sheetdsl::demo::Statemachine::TripleGrid;
import sheetdsl::demo::Statemachine::Definitions;

import sheetdsl::util::Node2adt;
import Node;
import salix::App;
import salix::Core;
import util::Maybe;
import sheetdsl::Syntax;
import Message;
import ParseTree;
import IO;
import Set;
App[TripleModel] main() {
    start[MGL] sensors = parse(#start[MGL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_sensors.mgl|);
    start[MGL] states = parse(#start[MGL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_states.mgl|);
    start[MGL] activations = parse(#start[MGL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_activations.mgl|);
    return initTripleApp("Statemachine", "Sensors",     sensors,    
                                         "States",      states,    
                                         "Activations", activations,
                      runFunc=just(runStatemachine));
}


void runStatemachine(list[node] nodes) {
    println("\nRunning Statemachine... \n");
    
}