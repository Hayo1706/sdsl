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
    start[SDSL] sensors = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_sensors.sdsl|);
    start[SDSL] states = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_states.sdsl|);
    start[SDSL] activations = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_activations.sdsl|);
    return initTripleApp("Statemachine", "Sensors",     sensors,    
                                         "States",      states,    
                                         "Activations", activations,
                      runFunc=just(runStatemachine));
}


void runStatemachine(list[node] nodes) {
    println("\nRunning Statemachine... \n");
    
}