module sheetdsl::demo::Statemachine::TripleGrid

import sheetdsl::SpreadSheets;
import sheetdsl::ParserSDSL;
import sheetdsl::Syntax;

import sheetdsl::ui::Toolbar;
import sheetdsl::ui::SheetApp;
import sheetdsl::util::Error;
import sheetdsl::util::SyntaxReader;
import sheetdsl::util::Node2adt;
import sheetdsl::demo::Statemachine::Check;
import sheetdsl::demo::Statemachine::Definitions;

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;

import util::Math;
import List;
import Map;
import IO;
import String;
import Exception;
import util::Maybe;
import Message;
import Set;
import Node;


alias TripleModel = tuple[str id, Model sensors, Model states, Model activations, RunFunc runFunc, bool hasParsed, start[SDSL] sSensors, start[SDSL] sStates, start[SDSL] sActivations];

App[TripleModel] initTripleApp(
    str id,
    str idSensors, start[SDSL] sSensors, 
    str idStates, start[SDSL] sStates, 
    str idActivations, start[SDSL] sActivations, 
    RunFunc runFunc = nothing())
  = webApp(makeApp(
    id,TripleModel() { return initTriple(
        id,
        idSensors, sSensors,  
        idStates, sStates,  
        idActivations, sActivations, 
        runFunc=runFunc);},
    withIndex(id, id, tripleViewWithToolbar, css=["/demo/Statemachine/triple.css"]), updateTriple),
    |project://sdsl/src/sheetdsl|);


Matrix sensorDefaults = [
  ["T1", "\"Temperature Sensor\"", "integer",  "digital"]
];

Matrix stateDefaults = [
  ["1", "\"Heat\"",      "2",    "\"Transition when warmed up\"",   "T1 \> 30"],
  ["2", "\"Spin\"",      "3",    "\"Correct temperature reached\"", "T1 \> 95"],
  ["",  "",              "1",    "\"Machine too cold\"",            "T1 \< 30"],
  ["3", "\"Empty\"",     "",     "",                            ""]
];
Matrix activationDefaults = [
  ["1", "\"Heat\"",            "",    "",   "x",  ""],
  ["2", "\"Heat and spin\"",   "x",   "",   "x",  ""],
  ["3", "\"Empty drum\"",      "",    "x",  "",   ""]
];


TripleModel initTriple(
    str id,
    str idSensors, start[SDSL] sSensors, 
    str idStates , start[SDSL] sStates, 
    str idActivations, start[SDSL] sActivations, 
    RunFunc runFunc = nothing()) 
     = <id,
        initModel(idSensors, sSensors, sheet=spreadSheet(sheetData=spreadSheetData(sensorDefaults,rows=25, labels=getSheetLabels(sSensors)))),
        initModel(idStates, sStates, sheet=spreadSheet(sheetData=spreadSheetData(stateDefaults, rows=25,labels=getSheetLabels(sStates)))),
        initModel(idActivations, sActivations, sheet=spreadSheet(sheetData=spreadSheetData(activationDefaults, rows=25,labels=getSheetLabels(sActivations)))),
        runFunc, false, sSensors, sStates, sActivations
        >;

data Msg = sensorsmsg(Msg msg) | statesmsg(Msg msg) | activationsmsg(Msg msg) | parse() | run();

TripleModel updateTriple(Msg msg, TripleModel model){
    model.hasParsed = false;
    switch (msg){
        case sensorsmsg(Msg msg):
            model.sensors = update(msg, model.sensors);
        case statesmsg(Msg msg):
            model.states = update(msg, model.states);
        case activationsmsg(Msg msg):
            model.activations = update(msg, model.activations);
        case parse():{
            model.hasParsed = true;
            model.sensors = update(parseSheet(), model.sensors);
            model.states = update(parseSheet(), model.states);
            model.activations = update(parseSheet(), model.activations);

            if (model.sensors.sheet.comments == [] && model.states.sheet.comments == [] && model.activations.sheet.comments == []) {
                value sensors=          node2adt(parseMatrix(model.sensors.parsedData.parsed, model.sSensors), #Sensor);
                value states=            node2adt(parseMatrix(model.states.parsedData.parsed, model.sStates), #State);
                value activations= node2adt(parseMatrix(model.activations.parsedData.parsed, model.sActivations), #Activations);

                model.states = replaceErrors(check(states, sensors),model.states);
                model.activations = replaceErrors(check(activations, states),model.activations);
            }
        }
        case run():{
            println("runSheet...");
        }
    }
    return model;
}

void tripleViewWithToolbar(TripleModel m) {
    bool noErrors = (0 | it + 1 | commentData(_,_,_, parseerror()) <- m.sensors.sheet.comments) == 0
        && (0 | it + 1 | commentData(_,_,_, parseerror()) <- m.states.sheet.comments) == 0
        && (0 | it + 1 | commentData(_,_,_, parseerror()) <- m.activations.sheet.comments) == 0;

    bool canParse = !m.hasParsed && noErrors;
    bool canRun = m.hasParsed && (0 | it + 1 | commentData(_,_,_, error()) <- m.sensors.sheet.comments) == 0
        && (0 | it + 1 | commentData(_,_,_, error()) <- m.states.sheet.comments) == 0
        && (0 | it + 1 | commentData(_,_,_, error()) <- m.activations.sheet.comments) == 0;
    
    div(style(("display":"inline-block", "gap":"2px")), () {
        parsebtn(parse(), canParse);
        runbtn(run(),canRun);
    });
    div(class("triple-wrapper"),() {
        div(() {
            h2(class("title"),"Sensors");
            div(style(("display":"inline-block", "gap":"2px")), () {
                importCSV(m.sensors.name);
                exportCSV(m.sensors.name);
            });
            mapView(sensorsmsg, m.sensors, view);
        });
        div(() {
            h2(class("title"),"States & Transitions");
            div(style(("display":"inline-block", "gap":"2px")), () {
                importCSV(m.states.name);
                exportCSV(m.states.name);
            });
            mapView(statesmsg, m.states, view);
        });
        div(() {
            h2(class("title"),"Activations");
            div(style(("display":"inline-block", "gap":"2px")), () {
                importCSV(m.activations.name);
                exportCSV(m.activations.name);
            });
            mapView(activationsmsg, m.activations, view);
        });
    });
}

