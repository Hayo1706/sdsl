module sheetdsl::ui::SheetWithToolbar

import sheetdsl::ui::Toolbar;
import sheetdsl::ui::SheetApp;
import sheetdsl::SpreadSheets;
import sheetdsl::Syntax;

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;

import IO;
import Message;
import Node;


alias ToolBarModel = tuple[Model sheet,bool hasParsed, bool canRunWithWarnings];

App[ToolBarModel] init(str id, start[SDSL] s, ParseFunc parseFunc = set[Message](list[node] n){return {};}, RunFunc runFunc = void(list[node] n){;}, bool canRunWithWarnings = true)
  = webApp(makeApp(id,ToolBarModel() { return initToolBarModel(id, s, parseFunc=parseFunc, runFunc=runFunc, canRunWithWarnings=canRunWithWarnings);},withIndex(id, id, viewWithToolbar, css=["/min.css"]), updateToolbar),|project://sdsl/src/sheetdsl/ui|);

ToolBarModel initToolBarModel(str id, start[SDSL] s, ParseFunc parseFunc = set[Message](list[node] n){return {};},
  RunFunc runFunc = void(list[node] n){;}, bool canRunWithWarnings = true) = <initModel(id, s, parseFunc=parseFunc, runFunc=runFunc), false, canRunWithWarnings>;

ToolBarModel updateToolbar(Msg msg, ToolBarModel model){
  println("<msg>");
  switch (msg){
    case parseSheet():{
      println("Parsing sheet...");
      model.sheet = update(msg, model.sheet);
      model.hasParsed = true;
    }
    case runSheet():{
      model.sheet = update(msg, model.sheet);
    }
    case sheetEdit(map[str,value] newValues):{
      println("Editing sheet...");
      model.hasParsed = false;
      model.sheet = update(msg, model.sheet);
    }
  }
  return model;
}

void viewWithToolbar(ToolBarModel m) {
  int parseErrors = (0 | it + 1 | commentData(_,_,_, parseerror()) <- m.sheet.sheet.comments);
  int errors = (0 | it + 1 | commentData(_,_,_, error()) <- m.sheet.sheet.comments);

  bool canParse = !m.hasParsed && parseErrors == 0;
  bool canRun = m.hasParsed && errors == 0;

  if (!m.canRunWithWarnings && (0 | it + 1 | commentData(_,_,_, warning()) <- m.sheet.sheet.comments) > 0)
    canRun = false;
  
  div(class("hot-wrapper"),() {
    toolBar(m.sheet.name, parseSheet(), runSheet(), canParse, canRun);
    // mapView(sheetMsg, m.sheet, view);
    view(m.sheet);
  });
}

