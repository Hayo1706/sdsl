module sheetdsl::demo::Statemachine::Main
import sheetdsl::demo::Statemachine::TripleGrid;

import Node;
import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;

import sheetdsl::Syntax;
import Message;
import ParseTree;
import IO;
import Set;
App[TripleModel] main() {
    start[SDSL] sensors = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_sensors.sdsl|);
    start[SDSL] states = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_states.sdsl|);
    start[SDSL] activations = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Statemachine/sm_activations.sdsl|);
    return initTripleApp("Statemachine", "Sensors", sensors, parseSensors,
                      "States", states, parseStates,
                      "Activations", activations, parseActivations,
                      runFunc=runStatemachine);
}

set[Message] parseSensors(list[node] nodes) {
    println("Parsing sensors...");
    //For now we dont do any checks yet
    set[Message] errors = {};
    return errors;
}
set[Message] parseStates(list[node] nodes) {
    println("Parsing states...");
    //For now we dont do any checks yet
    set[Message] errors = {};
    return errors;
}
set[Message] parseActivations(list[node] nodes) {
    println("Parsing activations...");
    //For now we dont do any checks yet
    set[Message] errors = {};
    return errors;
}

void runStatemachine(list[node] nodes) {
    println("\nRunning Statemachine... \n");
    
}