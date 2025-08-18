module sheetdsl::demo::QL::MultipleFormsApp

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;
import IO;
import sheetdsl::demo::QL::Definitions;
import sheetdsl::demo::QL::Eval;
import List;
import String;

import sheetdsl::demo::QL::App;

//This module is a variant of the QL app, but it allows multiple forms to be run in parallel.
// The forms have independent state, and can be run independently, but shown in the same UI.
App[MultipleModel] runMultipleQL(list[Forms] qls) = webApp(qlApp(qls), |project://sdsl/src/sheetdsl/demo/QL|);

SalixApp[MultipleModel] qlApp(list[Forms] qls, str id="QLs") 
  = makeApp(id, 
        MultipleModel() { return [<ql, initialEnv(ql)> | ql <- qls]; }, 
        withIndex("Forms"[1..-1], id, viewMultiple, css=["https://cdn.simplecss.org/simple.min.css"]), 
        updateMultiple);


alias MultipleModel = list[Model];

data Msg = sub1(int idx, Msg m);

Msg(Msg) subMsg(int idx) = Msg(Msg m){ return sub1(idx, m); };

MultipleModel updateMultiple(Msg msg, MultipleModel models) {
    models[msg.idx] = update(msg.m, models[msg.idx]);
    return models;
}

void viewMultiple(MultipleModel models){
    div(style(("display":"block")),() {
        for (int i <- [0..size(models)]) {
            mapView(subMsg(i), models[i], view);
        }
    });
}