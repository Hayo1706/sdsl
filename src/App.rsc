module App

import Charts;

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;
import salix::Node;

import util::Math;
import List;
import IO;
import Syntax;
import Exception;

import String;
import ParseTree;
import lang::json::IO;

alias RowModel = RowData;
alias Model = SheetData;

App[Model] runWebSDSL(start[SDSL] s) = webApp(sdslApp(s), |project://sdsl/src|);

App[Model] testrunWebSDSL() = webApp(sdslApp(parse(#start[SDSL], |project://sdsl/src/test.sdsl|)), |project://sdsl/src|);


SalixApp[Model] sdslApp(start[SDSL] s, str id = "root") 
  = makeApp(id,
          Model() { return initModel(s,100,50);}, 
          withIndex("SDSL", id, view, css=["assets/css/min.css"],
          scripts=["assets/javascript/table-resize.js","assets/javascript/selection.js","assets/javascript/viewport.js"]), 
          update
);

Model initModel(start[SDSL] s, int amountrows, int amountCols) {
  list[RowData] table = [];
  for (int i <- [0..amountrows]){
    list[value] row = [];
    for(int i2 <- [0..amountCols]){
      row = row + "";
    }
    table = table + rowData(i, "<i>", row);
  }
  list[HeaderData] columns = [];
  for (int i <- [0..amountCols]){
    columns = columns + headerData("Col<i>");
  }

  return sheetData(columns,table, s, [0,0,amountrows,amountCols]);
}

data SheetData = sheetData(
  list[HeaderData] cols,
  list[RowData] tableData,
  start[SDSL] s,
  list[int] viewport
);

data RowData = rowData(
  int rowIndex,
  str rowHeader,
  list[value] cellData 
);

data Msg
  = testing(value v1, value v2)
  | changedCellValue(value rowCol, value content)
  | changedViewPort(value pos1, value pos2)
  | bulkChange(map[str,value] difference);

data HeaderData = headerData(
  str name
);

&T cast(type[&T] t, value x) {
  if (&T e := x) 
     return e;
  throw "cast exception <x> can not be matched to <t>";
} 

Model update(Msg msg, Model m){
  switch(msg){
    case testing(value v1, value v2):{
      println("1:<v1> 2:<v2>");
    }
    case changedCellValue(str idx, str content):{
      list[int] rowCol = [ toInt(s) | s <- split(",",idx)];
      m.tableData[rowCol[0]].cellData[rowCol[1]] = content;
    }
    case changedViewPort(str pos1, str pos2):{
      list[int] rowColPos1 = [ toInt(s) | s <- split(",",pos1)];
      list[int] rowColPos2 = [ toInt(s) | s <- split(",",pos2)];
      m.viewport = rowColPos1 + rowColPos2;
    }
    case bulkChange(map[str,value] diff):{
      visit (diff["payload"]) {
        case "object"(col=int col, change=change, row=int row):{
          m.tableData[row].cellData[col] = change;
        }
      }
    }
  }
  return m;
}


void view(Model m) {
  encode(testing);
  encode(changedCellValue);
  encode(changedViewPort);
  encode(bulkChange);
  input(id("editor"),\type("text"),\class("editor"));
  table(id("myTable"),() {
    thead(() {
      tr(() {
        th("");
        for (HeaderData s <- m.cols){
          th(s.name);
        }
      });
    });
    tbody(() {
      for (RowModel i <- m.tableData) {
        rowView(i, m.viewport);
      }
    });
  });
}

void rowView(RowModel m, list[int] viewport) {
  tr(class("trheight"),attr("aria-rowindex","<m.rowIndex>"),() {
    if (m.rowIndex >= viewport[0] && m.rowIndex <= viewport[2]){
      th(m.rowHeader);
      for (int  i <- [0..(min(size(m.cellData), viewport[3]))]){
        cellView(i,m.cellData[i]);
      }
    }
  });
}

void cellView(int idx, value content){
  td(
    attr("aria-colindex","<idx>"),
    tabindex(-1),
    content
  );
}