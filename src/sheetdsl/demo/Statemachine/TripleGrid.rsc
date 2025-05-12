module sheetdsl::demo::Statemachine::TripleGrid

import sheetdsl::ui::Toolbar;
import sheetdsl::ui::SheetApp;

import sheetdsl::SpreadSheets;
import sheetdsl::ParserSDSL;
import sheetdsl::util::Error;
import sheetdsl::Syntax;

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


alias TripleModel = tuple[str id, Model sensors, Model states, Model activations, RunFunc runFunc, bool hasParsed];

App[TripleModel] initTripleApp(
    str id,
    str idSensors, start[SDSL] sSensors, ParseFunc parseFuncSensors,
    str idStates, start[SDSL] sStates, ParseFunc parseFuncStates,
    str idActivations, start[SDSL] sActivations, ParseFunc parseFuncActivations,
    RunFunc runFunc = void(list[node] n){;})
  = webApp(makeApp(
    id,TripleModel() { return initTriple(
        id,
        idSensors, sSensors, parseFuncSensors, 
        idStates, sStates, parseFuncStates, 
        idActivations, sActivations, parseFuncActivations, 
        runFunc=runFunc);},
    withIndex(id, id, tripleViewWithToolbar, css=["/demo/Statemachine/triple.css"]), updateTriple),
    |project://sdsl/src/sheetdsl|);

TripleModel initTriple(
    str id,
    str idSensors, start[SDSL] sSensors, ParseFunc parseFuncSensors,
    str idStates , start[SDSL] sStates, ParseFunc parseFuncStates,
    str idActivations, start[SDSL] sActivations, ParseFunc parseFuncActivations,
    RunFunc runFunc = void(list[node] n){;}) 
    = <id,
       initModel(idSensors, sSensors, parseFunc=parseFuncSensors),
       initModel(idStates, sStates, parseFunc=parseFuncStates),
       initModel(idActivations, sActivations, parseFunc=parseFuncActivations),
       runFunc, false
       >;

data Msg = sensors(Msg msg) | states(Msg msg) | activations(Msg msg) | parse() | run();

TripleModel updateTriple(Msg msg, TripleModel model){
    model.hasParsed = false;
    switch (msg){
        case sensors(Msg msg):
            model.sensors = update(msg, model.sensors);
        case states(Msg msg):
            model.states = update(msg, model.states);
        case activations(Msg msg):
            model.activations = update(msg, model.activations);
        case parse():{
            model.hasParsed = true;
            model.sensors = update(parseSheet(), model.sensors);
            model.states = update(parseSheet(), model.states);
            model.activations = update(parseSheet(), model.activations);
        }
        case run():{
            println("runSheet");
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
            mapView(sensors, m.sensors, view);
        });
        div(() {
            h2(class("title"),"States & Transitions");
            div(style(("display":"inline-block", "gap":"2px")), () {
                importCSV(m.states.name);
                exportCSV(m.states.name);
            });
            mapView(states, m.states, view);
        });
        div(() {
            h2(class("title"),"Activations");
            div(style(("display":"inline-block", "gap":"2px")), () {
                importCSV(m.activations.name);
                exportCSV(m.activations.name);
            });
            mapView(activations, m.activations, view);
        });
    });
}

