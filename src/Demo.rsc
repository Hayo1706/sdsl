module Demo

import Charts;
import salix::App;
import salix::Core;
import salix::HTML;
import salix::Index;

import List;
import util::Math;
import IO;


SalixApp[Model] chartApp(str id = "charts") 
  = makeApp(id, init, withIndex("Charts", id, view,css=["/min.css"]), update);

App[Model] chartWebApp()
  = webApp(chartApp(), |project://sdsl/src|);


// alias SheetData = map[int,map[str,value]];
// alias ColumnData = map[str,str];

//alias Model = tuple[SheetData, ColumnData];

alias RowId = int;
alias ColumnId = str;

alias RowData = map[ColumnId, value];
alias Table = map[RowId, RowData];

alias RowOrder = list[RowId];

int nextRowId = 0;

//alias Model = map[str, list[value]];
//list[str] columnnames = ["name", "age", "ismarried", "hasdog", "amountchildren"];

ColumnData columnData = ("name": "text", "age": "numeric", "ismarried": "checkbox", "hasdog": "checkbox", "amountchildren": "numeric");

//Model init() = (name:  ["" | a <- [0.99]] | name <- columnnames );

Model init() = <(), columnData>;

data Msg
  = sheetEdit(map[str,value] newValues)
  | sheetSetMessage()
  | sheetRemoveMessage()
  | rowCreateMessage(int index, int amount)
  | rowRemoveMessage(int index, int amount);


Model update(Msg msg, Model model){
  switch(msg){
    case sheetEdit(map[str,value] sheet):{
      list[value] x = cast(#list[value],sheet["payload"]);
      int row = cast(#int,x[0]);
      str prop = cast(#str,x[1]);
      value oldValue = x[2];
      value newValue = x[3];
      SheetData a = model[0];
      if (a[row]?)
        a[row][prop] = newValue;
      else
        a[row] = (prop: newValue);
      
      if (newValue == "")
        do(sheetRemoveMessage("mychart",sheetRemoveMessage(), "<row>", prop));
      else
        do(sheetSetMessage("mychart",sheetSetMessage(), "<row>", prop, "You have changed " + prop));

      return <a, model[1]>;
    }
  }
  return model;
  
}

&T cast(type[&T] t, value x) {
  if (&T e := x) 
     return e;
  throw "cast exception <x> can not be matched to <t>";
} 

void view(Model m) {
    spreadsheet("mychart", m, onSheetChange(sheetEdit),
     onRowCreate(rowCreateMessage), onRowRemove(rowRemoveMessage));
    print("Hello World");
}