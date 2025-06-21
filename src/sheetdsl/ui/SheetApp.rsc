module sheetdsl::ui::SheetApp

import sheetdsl::ui::Alien;
import sheetdsl::SpreadSheets;
import sheetdsl::util::Error;
import sheetdsl::util::SyntaxReader;
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
import Type;

import ParseTree;
import Grammar;
import lang::rascal::\syntax::Rascal;
import lang::rascal::format::Grammar;
import lang::rascal::grammar::definition::Productions;
import lang::rascal::grammar::definition::Layout;
import lang::rascal::grammar::definition::Symbols;


alias ParsedData = tuple[Matrix raw, Matrix parsed];
alias ParseFunc = Maybe[set[Message](list[node])];
alias RunFunc   = Maybe[void(list[node])];


alias Model = tuple[str name,
                    start[SDSL] s, 
                    SpreadSheet sheet, 
                    map[int, type[&T<:Tree]] colTypes, 
                    ParsedData parsedData,
                    ParseFunc parseFunc,
                    RunFunc runFunc,
                    bool autoParse
              ];

ParsedData getStartingParseData(int rows, int cols) = <[["" | int _ <- [0..cols]] | int i <-[0..rows]], [["" | int _ <- [0..cols]] | int i <-[0..rows]]>;
SpreadSheet getStartingSpreadSheet(start[SDSL] s, int rows) = spreadSheet(sheetData=spreadSheetData(rows, getSheetLabels(s)));

App[Model] initSheetWebApp(str id, start[SDSL] s, int rows = 25, 
    SpreadSheet sheet = getStartingSpreadSheet(s, rows), 
    ParseFunc parseFunc=nothing(), RunFunc runFunc=nothing(),
    bool autoParse = true,
    list[str] extraCss = []
    ) 
    = webApp(initSheetApp(id, s, rows=rows, sheet=sheet, parseFunc=parseFunc, runFunc=runFunc, autoParse=autoParse, extraCss=extraCss),|project://sdsl/src|);


SalixApp[Model] initSheetApp(str id, start[SDSL] s, int rows = 25, 
    SpreadSheet sheet = getStartingSpreadSheet(s, rows), 
    ParseFunc parseFunc = nothing(), RunFunc runFunc = nothing(),
    bool autoParse = true,
    list[str] extraCss = []
    )
    = makeApp(id,Model() { return initModel(id, s, rows=rows, sheet=sheet, parseFunc=parseFunc, runFunc=runFunc, autoParse=autoParse);}, withIndex(id, id, view, css=["sheetdsl/ui/min.css"] + extraCss), update);


Model initModel(str id, start[SDSL] s, int rows = 25, 
SpreadSheet sheet = getStartingSpreadSheet(s, rows), 
ParseFunc parseFunc=nothing(), RunFunc runFunc = nothing(),
bool autoParse = true
) {
  map[int, type[&T<:Tree]] colTypes = ();
  SyntaxDefinition lay = (SyntaxDefinition)`layout WS = [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000]* !\>\> [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000];`;
  Grammar gr = \layouts(syntax2grammar(lay + {syn | SyntaxDefinition syn <- s.top.grammarDefs}), \layouts("WS"), {});
  list[Element] columns = getSheetColumns(s);
  for (int i <- [0..size(columns)]) {
      Column c = columns[i].column;
      Symbol s;
      if (sort("<c.ref>") in domain(gr.rules)) 
          s = sort("<c.ref>");
      else
          throw ("Column <c.ref> not found in grammar, or does not have a Syntax Symbol");
      colTypes[i] = type(s,gr.rules);
  }

  return fillWithDefaults(sheet.sheetData.\data, <id,s,sheet,colTypes, getStartingParseData(size(sheet.sheetData.rowHeaders), size(sheet.sheetData.columnHeaders)), parseFunc, runFunc, autoParse>);
}


data Msg = sheetEdit(map[str,value] newValues) | parseSheet() | runSheet();


private Model fillWithDefaults(Matrix raw, Model m){
  for (int r <- index(raw))
    for (int c <- index(raw[r]))
      if (raw[r][c] != "")
        m = parseChanges(r, c, raw[r][c], m);
  return m;
}


Model parseChanges(int row, int col, value change, Model model){
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
    return model;
}

Model replaceErrors(set[Message] errs, Model model, bool ParseError = false){
  list[CommentData] tempComments = []; 
  for (Message err <- errs){
    ans = messageToCommentData(err, ParseError);
    tempComments += ans[0];
    model.sheet.sheetData.\data[ans[1]][ans[2]] = highlightErrorSubstring(model.parsedData.raw[ans[1]][ans[2]], err.at.begin.column,err.at.end.column);
  }
  model.sheet.comments = tempComments;
  return model;
}

Model parse(Model model) {
    set[Message] errs = checkRequiredBlocks(model.parsedData.raw, model.s);
    bool missingCells = size(errs) > 0;
    if (!missingCells && model.parseFunc != nothing())
      errs = model.parseFunc.val(parseMatrix(model.parsedData.parsed, model.s));
    return replaceErrors(errs, model, ParseError=missingCells);
}



Model update(Msg msg, Model model){
  switch (msg){
    case sheetEdit(map[str,value] diff):{
      visit (diff["payload"]) {
        case "object"(col=int col, change=change, row=int row):{
          model = parseChanges(row, col, change, model);
        }
      }
      if (model.autoParse && (0 | it + 1 | commentData(_,_,_, warning()) <- model.sheet.comments) == size(model.sheet.comments) ) {
        model = parse(model);
      }
    }
    case parseSheet():{
      model = parse(model);
    }
    case runSheet():{
      if (model.runFunc != nothing()) 
        model.runFunc.val(parseMatrix(model.parsedData.parsed, model.s));
    }
  }
  return model;
}


void view(Model m) {
    spreadsheet(
      m.sheet,
      m.name,
      onSheetChange(sheetEdit)
    );
}


