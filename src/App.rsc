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

alias Model = tuple[start[SDSL] s, SheetTable t];

App[Model] runWebSDSL(start[SDSL] s) = webApp(sdslApp(s), |project://sdsl/src|);

App[Model] testrunWebSDSL() = webApp(sdslApp(parse(#start[SDSL], |project://sdsl/src/test.sdsl|)), |project://sdsl/src|);


SalixApp[Model] sdslApp(start[SDSL] s, str id = "root") 
  = makeApp(id,
          Model() { return initModel(s,10,5);}, 
          withIndex("SDSL", id, view, css=["assets/css/min.css"],scripts=["assets/javascript/table-resize.js","assets/javascript/testing.js"]), 
          update
);

Model initModel(start[SDSL] s, int amountrows, int amountCols) {
  list[list[value]] table = [];
  for (int i <- [0..amountrows]){
    list[value] row = [];
    for(int i2 <- [0..amountCols]){
      row = row + "";
    }
    table = table + [row];
  }
  list[HeaderData] columns = [];
  for (int i <- [0..amountCols]){
    columns = columns + headerData("Col<i>");
  }
  list[HeaderData] rows = [];
  for (int i <- [0..amountrows]){
    rows = rows + headerData("Row<i>");
  }

  return <s, sheetTable(columns,rows,table,<-1,-1>,<-1,-1>,<-1,-1>, false)>;
}

data SheetTable = sheetTable(
  list[HeaderData] cols,
  list[HeaderData] rows,
  list[list[value]] tableData,
  tuple[int row, int col] activeCell,
  tuple[int row, int col] dragpos1,
  tuple[int row, int col] dragpos2,
  bool dragging

);

data Msg
  = cellClicked(int row, int col)
  | changeValue(value content, int row, int col)
  | deselect()
  | startDrag(int row, int col)
  | moveDrag(int row, int col)
  | stopDrag(int row, int col)
  | dragStartedHandle(str t);

Msg(str) changeValue(int row, int col) = Msg(str s) { return changeValue(s, row, col); };

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
    case cellClicked(int row, int col):{
      m.t.activeCell = <row, col>;
    }
    case changeValue(value s, int row, int col):{
      m.t.tableData[row][col] = s;
      m.t.activeCell = <-1,-1>;
    }
    case deselect():{
      m.t.activeCell = <-1,-1>;
      m.t.dragpos1 = <-1,-1>;
      m.t.dragpos2 = <-1,-1>;
      m.t.dragging = false;
    }
    case startDrag(int row, int col):{
      m.t.activeCell = <-1, -1>;
      m.t.dragpos2 = <-1,-1>;
      m.t.dragpos1 = <row,col>;
      m.t.dragging = true;
    }
    case moveDrag(int row, int col):{
      if (m.t.dragging && m.t.dragpos1 != <row, col>){
        m.t.dragpos2 = <row, col>;
      }
    }
    case stopDrag(int row, int col):{
      m.t.dragging = false;
    }
  }
  return m;
}


void view(Model m) {
  table(id("myTable"),() {
    thead(() {
      tr(() {
        th("");
        for (HeaderData s <- m.t.cols){
          th(s.name);
        }
      });
    });
    tbody(() {
      for (int i <- [0..size(m.t.rows)]){
        tr(() {
          th(m.t.rows[i].name);
          for (int i2 <- [0..size(m.t.cols)]){
            cellView(m,i,i2,m.t.tableData[i][i2]);
          }
        });
      }
    });
  });
}

void cellView(Model m, int row, int col, value content){
  Attr inSelection = null();
  Attr mouseMove = null();
  if(isCellInSelection(row, col, m.t.dragpos1.row, m.t.dragpos1.col, m.t.dragpos2.row, m.t.dragpos2.col) && m.t.dragpos1 != <-1,-1> && m.t.dragpos2 != <-1,-1>){
    inSelection= \class("selection"); 
  }
  if (m.t.dragging){
    mouseMove= \onMouseEnter(moveDrag(row, col));
  }

  //edit mode
  if (m.t.activeCell == <row,col>){
    td(() {
      input(
        \value(content),
        \type("text"),
        \class("inputclass"),
        \onChange(changeValue(row, col)),
        \onBlur(deselect()),
        inSelection,
        \onMouseDown(startDrag(row, col)),
        mouseMove,
        \onMouseUp(stopDrag(row, col))
      );
    });
  }
  else{
    //view mode
    td(
      \onClick(cellClicked(row, col)),
      \onBlur(deselect()),
      inSelection,
      \onMouseDown(startDrag(row, col)),
      mouseMove,
      \onMouseUp(stopDrag(row, col)),
      \draggable("false"),
      content
    );
  }
}

bool isCellInSelection(int r, int c, int r1, int c1, int r2, int c2) {
  int minR = min(r1, r2);
  int maxR = max(r1, r2);
  int minC = min(c1, c2);
  int maxC = max(c1, c2);
  
  return (r >= minR && r <= maxR) && (c >= minC && c <= maxC);
}