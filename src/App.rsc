module App

import Alien;
import SpreadSheets;
import ParserSDSL;
import vis::Text;
import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;
import util::Math;
import List;
import Map;
import IO;
import Syntax;
import String;
import Exception;
import util::Maybe;

import ParseTree;
import lang::rascal::\syntax::Rascal;
import lang::rascal::format::Grammar;
import Grammar;
import lang::rascal::grammar::definition::Productions;
import lang::rascal::grammar::definition::Layout;
import lang::rascal::grammar::definition::Symbols;
import Node;

alias Model = tuple[start[SDSL] s, SpreadSheet sheet, map[Symbol, Production] rules, map[int, str] colSyntax, list[list[value]] parsedData];
SyntaxDefinition lay = (SyntaxDefinition)`layout WS = [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000]* !\>\> [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000];`;

App[Model] runWebSDSL(start[SDSL] s) = webApp(sdslApp(s), |project://sdsl/src|);

App[Model] testrunWebSDSL() = webApp(sdslApp(parse(#start[SDSL], |project://sdsl/src/test.sdsl|)), |project://sdsl/src|);


SalixApp[Model] sdslApp(start[SDSL] s, str id = "root") 
  = makeApp(id,
          Model() { return initModel(s);}, 
          withIndex("SDSL", id, view, css=["assets/css/min.css"],scripts=["/assets/javascript/customEditor.js"]), 
          update
);
SpreadSheet generate(SpreadsheetData \data) 
  = spreadSheet(
    sheetData=\data
  );

Model initModel(start[SDSL] s, int rows = 50) {
  list[str] columns = [];
  map[int,str] symbols = ();
  visit(s){
    case Column c:{
      columns += "<c.name>"[1..-1];
      symbols[size(columns) -1] = "<c.ref>";
    }
  }

  Grammar gr = \layouts(syntax2grammar(lay + {syn | SyntaxDefinition syn <- s.top.grammarDefs}), \layouts("WS"), {});
  return <s, generate(spreadSheetData(rows, columns)), gr.rules, symbols, [["" | int _ <- [0..size(columns)]] | int i <-[0..rows]]>;
}
data Msg
  = sheetEdit(map[str,value] newValues)
  | parseSheet();

Model update(Msg msg, Model model){
  switch(msg){
    case sheetEdit(map[str,value] diff):{
      visit (diff["payload"]) {
        case "object"(col=int col, change=change, row=int row):{
          try{ 
            if (change != ""){model.parsedData[row][col] = parse(type(sort(model.colSyntax[col]), model.rules),change);}
            else{ model.parsedData[row][col] = "";}
            model.sheet.sheetData.\data[row][col] = change;
            model.sheet.comments = removeComment(model.sheet.comments, row, col);
          }
          catch ParseError(loc location):{
            model.sheet.comments = replaceComment(model.sheet.comments, row, col, "<location>");
            model.sheet.sheetData.\data[row][col] = highlightErrorSubstring(change, location.begin.column,location.end.column);
          }
          
        }
      }
    }
    case parseSheet:{
      tree = parseData(model.parsedData, model.s);
      println(tree);
      println("\nConverting node to adt...\n");
      abc = node2data(tree, #Forms, model.s);
      //println(abc);
      //Check if pattern matching works
      visit(abc){
        case question(q,_,_,nothing(),_,e):{
          println("Question: <q> has a value of nothing");
          println(e);
          if ((Expr)`<Expr e1>|| <Expr e2>`:= e){
            println("Question: <q> has a condition of <e1> or <e2>");
          }
        }
        case e:(Expr)`<Expr e1>|| <Expr e2>`:{
          println("AAAAAAAAAAAA<e>");
        }

      }
    }
  }
  return model;
}

void view(Model m) {
  button(\onClick(parseSheet()),"PARSE");
  spreadsheet(
    m.sheet,
    "mychart",
    onSheetChange(sheetEdit)
  );
}


public str highlightErrorSubstring(str code, int \start, int end) {
    str before = substring(code, 0, \start);
    str error  = substring(code, \start, end);
    str after  = substring(code, end);

    str background = "";
    if (trim(error) == "")
      background = "style=\"background: red\"";

    return "\<pre id=\"hltx\"\>" 
          + before 
          + "\<span <background> id=\"hltx\" class=\"errorText\"\>" 
          + error 
          + "\</span id=\"hltx\"\>" 
          + after
          + "\</pre id=\"hltx\"\>";
}