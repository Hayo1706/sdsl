module App

import Charts;

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;

import util::Math;
import List;
import IO;
import Syntax;
import Exception;

import String;
import ParseTree;

alias Model = tuple[start[SDSL] s, SheetTable t];

App[Model] runWebSDSL(start[SDSL] s) = webApp(sdslApp(s), |project://sdsl/src|);

App[Model] testrunWebSDSL() = webApp(sdslApp(parse(#start[SDSL], |project://sdsl/src/test.sdsl|)), |project://sdsl/src|);


SalixApp[Model] sdslApp(start[SDSL] s, str id = "root") 
  = makeApp(id,
          Model() { return <s, sheetTable(SDSLColumns(s), [])>;}, 
          withIndex("SDSL", id, view, css=["/min.css"]), 
          update
);


data Msg
  = sheetEdit(map[str,value] newValues)
  | sheetSetMessage();


data SheetTable = sheetTable(
  list[ColumnData] columns,
  list[list[value]] tableData
);

data ColumnData = columnData(
  str name,
  str inputType,
  Type* dataTypes
);

list[ColumnData] SDSLColumns(start[SDSL] s){
  list[ColumnData] columns = [];
  visit(s){
    case Column c: {
      columns += columnData("<c.name>"[1..-1], "text", c.types);
    }
  }
  return columns;
}

str ColumnNamesToString(list[ColumnData] a){
  str columnconstant = "[";
  for(ColumnData d <- a){
    columnconstant += "\"" + d.name + "\",";
  }
  columnconstant += "]";
  return replaceAll(columnconstant, "\"", "\'");
}


&T cast(type[&T] t, value x) {
  if (&T e := x) 
     return e;
  throw "cast exception <x> can not be matched to <t>";
} 

map[str,value] checkChange(list[value] change, Model model){
  str message = "";
  if (change[3] != ""){
    for (Type t <- model.t.columns[cast(#int ,change[1])].dataTypes){
      if (t == [Type]"string"){
        message = "";
        break;
      }
      str reponse = checkType(change[3],t);
      if (reponse == ""){
        message = "";
        break;
      }
      if (message != "")
        message += " or ";
      message += reponse;
    }
  }
  if (message != "")
   message = "This value should be " + message;
  
  return ("row":change[0],"column":change[1],"message":message);
}

str checkType(val,(Type)`boolean`) {try [Bool]"<val>"; catch ParseError(e): return "\'true\' or \'false\'"; return "";}
str checkType(val,(Type)`integer`) {try [Int]"<val>"; catch ParseError(e): return "a number"; return "";}
default str checkType(val, Type _) = "";



Model update(Msg msg, Model model){
  switch(msg){
    case sheetEdit(map[str,value] sheet):{
      list[value] change = cast(#list[value],sheet["payload"]);  

      do(sheetSetMessage("mychart", sheetSetMessage(), ("comments":[checkChange(change,model)], "reset":false)));
    }
  }
  return model;
  
}


void view(Model m) {
  spreadsheet(
    "mychart", 
    size(m.t.columns),
    ColumnNamesToString(m.t.columns),
    event=onSheetChange(sheetEdit)
  );

}