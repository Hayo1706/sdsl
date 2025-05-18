module sheetdsl::ui::SheetApp

import sheetdsl::ui::Alien;
import sheetdsl::SpreadSheets;
import sheetdsl::util::Error;
import sheetdsl::Syntax;
import sheetdsl::ParserSDSL;

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

import ParseTree;
import Grammar;
import lang::rascal::\syntax::Rascal;
import lang::rascal::format::Grammar;
import lang::rascal::grammar::definition::Productions;
import lang::rascal::grammar::definition::Layout;
import lang::rascal::grammar::definition::Symbols;

alias ParsedData = tuple[Matrix raw, Matrix parsed];
alias ParseFunc = set[Message](list[node]);
alias RunFunc   = void(list[node]);

alias Model = tuple[str name,
                    start[SDSL] s, 
                    SpreadSheet sheet, 
                    map[int, type[&T<:Tree]] colTypes, 
                    ParsedData parsedData,
                    ParseFunc parseFunc,
                    RunFunc runFunc
              ];

App[Model] initSheetApp(str id, start[SDSL] s, ParseFunc parseFunc = set[Message](list[node] n){return {};}, RunFunc runFunc = void(list[node] n){;})
  = webApp(makeApp(
        id,
        Model() { return initModel(id, s, parseFunc=parseFunc, runFunc=runFunc);}, 
        withIndex(id, id, view, css=["/min.css"]), 
        update),
      |project://sdsl/src/sheetdsl/ui|
  );

SpreadSheet generate(SpreadsheetData \data) = spreadSheet(sheetData=\data);

list[Element] getSheetColumns(start[SDSL] s, Block block = s.top.topBlock.b, map[str, Block] blocks = getBlocks(s)){
    list[Element] columns = [];
    for (Element e <- block.elems){
        if (e is col)
            columns += e;
        else if (e is sub){
            columns += getSheetColumns(s, block=blocks["<e.subBlock.name>"], blocks=blocks);
        }
    }
    return columns;
}

Model initModel(str id, start[SDSL] s, ParseFunc parseFunc = set[Message](list[node] n){return {};}, RunFunc runFunc = void(list[node] n){;}, int rows = 50) {
  SyntaxDefinition lay = (SyntaxDefinition)`layout WS = [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000]* !\>\> [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000];`;
  Grammar gr = \layouts(syntax2grammar(lay + {syn | SyntaxDefinition syn <- s.top.grammarDefs}), \layouts("WS"), {});

  list[Element] columns = getSheetColumns(s);
  map[int, type[&T<:Tree]] colTypes = ();

  for (int i <- [0..size(columns)]) {
    Column c = columns[i].column;
    Symbol s;
    if (sort("<c.ref>") in domain(gr.rules)) 
      s = sort("<c.ref>");
    else if (lex("<c.ref>") in domain(gr.rules)) 
      s = lex("<c.ref>");
    else
      throw ParseError("Column <c.ref> not found in grammar, or does not have a Syntax or Lexical Symbol");

    colTypes[i] = type(s,gr.rules);
  }
  
  SpreadSheet sheet = generate(spreadSheetData(rows, ["<e.column.name>"[1..-1] | Element e <- columns]));
  ParsedData parsedData = <[["" | int _ <- [0..size(columns)]] | int i <-[0..rows]], [["" | int _ <- [0..size(columns)]] | int i <-[0..rows]]>;

  return <id,s,sheet,colTypes,parsedData, parseFunc, runFunc>;

}
data Msg = sheetEdit(map[str,value] newValues) | parseSheet() | runSheet();

Model update(sheetEdit(map[str,value] diff), Model model){
  println("sheetEdit");
  visit (diff["payload"]) {
    case "object"(col=int col, change=change, row=int row):{
      model.parsedData.raw[row][col] = change;
      try{ 
        model.parsedData.parsed[row][col] = change != "" ? parse(model.colTypes[col], change, CoordsToLoc(row, col)) :"";
        model.sheet.sheetData.\data[row][col] = change;
        model.sheet.comments = removeComment(model.sheet.comments, row, col);
      }
      catch ParseError(loc location):{
        model.sheet.comments = replaceComment(model.sheet.comments, row, col, "ParseError( <location> )", parseerror());
        model.sheet.sheetData.\data[row][col] = highlightErrorSubstring(change, location.begin.column,location.end.column);
      }
    }
  }
  return model;
}

Model update(parseSheet(), Model model){
  set[Message] errs = checkRequiredBlocks(model.parsedData.raw, model.s);
  bool missingCells = size(errs) > 0;
  if (!missingCells)
    errs = model.parseFunc(parseMatrix(model.parsedData.parsed, model.s));
  
  list[CommentData] tempComments = [];
  for (Message err <- errs){
    ans = messageToCommentData(err, missingCells);
    tempComments += ans[0];
    model.sheet.sheetData.\data[ans[1]][ans[2]] = highlightErrorSubstring(model.parsedData.raw[ans[1]][ans[2]], err.at.begin.column,err.at.end.column);
  }

  model.sheet.comments = tempComments;
  return model;
}


Model update(runSheet(), Model model){
  model.runFunc(parseMatrix(model.parsedData.parsed, model.s));
  return model;
}

void view(Model m) {
    spreadsheet(
      m.sheet,
      m.name,
      onSheetChange(sheetEdit)
    );
}


