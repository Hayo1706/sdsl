module sheetdsl::SheetApp

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

//Store both the raw values which are entered by the user, and the parsed values which are the result of parsing the raw values with the grammar.
alias ParsedData = tuple[Matrix raw, Matrix parsed];
// Optionally provide a function to parse the data, or run the sheet.
alias ParseFunc = Maybe[set[Message](list[node])];
alias RunFunc   = Maybe[void(list[node])];


alias Model = tuple[str name,
                    start[MGL] s, 
                    SpreadSheet sheet, 
                    map[int, type[&T<:Tree]] colTypes, 
                    ParsedData parsedData,
                    ParseFunc parseFunc,
                    RunFunc runFunc,
                    bool autoParse
              ];

// Helper function to make an initial empty spreadSheet, with the given number of rows and the labels from the grammar.
SpreadSheet getBasicSpreadSheet(start[MGL] s, int rows) = spreadSheet(sheetData=spreadSheetData(rows, getSheetLabels(s)));


App[Model] initSheetWebApp(str id, start[MGL] s, SpreadSheet sheet, ParseFunc parseFunc=nothing(), RunFunc runFunc=nothing(), bool autoParse = true, list[str] extraCss = []) 
    = webApp(initSheetApp(id, s, sheet, parseFunc=parseFunc, runFunc=runFunc, autoParse=autoParse, extraCss=extraCss),|project://sdsl/src|);


SalixApp[Model] initSheetApp(str id, start[MGL] s, SpreadSheet sheet, ParseFunc parseFunc = nothing(), RunFunc runFunc = nothing(), bool autoParse = true,list[str] extraCss = [])
    = makeApp(id,Model() { return initModel(id, s, sheet, parseFunc=parseFunc, runFunc=runFunc, autoParse=autoParse);}, withIndex(id, id, view, css=["sheetdsl/ui/min.css"] + extraCss), update);


Model initModel(str id, start[MGL] s, SpreadSheet sheet, ParseFunc parseFunc=nothing(), RunFunc runFunc = nothing(),bool autoParse = true) {
  // Map that will hold the grammars of the columns, indexed by their column index.
  map[int, type[&T<:Tree]] colTypes = ();


  // make the grammar for the sheet, using the layout WS and the syntax definitions from the MGL.
  SyntaxDefinition lay = (SyntaxDefinition)`layout WS = [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000]* !\>\> [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000];`;
  Grammar gr = \layouts(syntax2grammar(lay + {syn | SyntaxDefinition syn <- s.top.grammarDefs}), \layouts("WS"), {});


  // Fill the map, check if the nonterminal references exist in the grammar.
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


  // Setup the 2d matrix, raw and parsed.
  Matrix emptyRaw = [["" | int _ <- [0..size(sheet.sheetData.columnHeaders)]] | int i <- [0..size(sheet.sheetData.rowHeaders)]];
  Matrix emptyParsed = [["" | int _ <- [0..size(sheet.sheetData.columnHeaders)]] | int i <- [0..size(sheet.sheetData.rowHeaders)]];


  // init model
  Model m = <id,s,sheet,colTypes, <emptyRaw, emptyParsed>, parseFunc, runFunc, autoParse>;

  // Parse all the data in the initial sheet once, if it is not empty.
  for (int r <- index(sheet.sheetData.\data))
    for (int c <- index(sheet.sheetData.\data[r]))
      if (sheet.sheetData.\data[r][c] != "")
        m = parseChanges(r, c, sheet.sheetData.\data[r][c], m);

  return m;
}

data Msg = sheetEdit(map[str,value] newValues) | parseSheet() | runSheet();


// parse the user input according to the grammar of the column type
Model parseChanges(int row, int col, value change, Model model){
    model.parsedData.raw[row][col] = change;
    try{ 
      model.parsedData.parsed[row][col] = change != "" ? parse(model.colTypes[col], change, CoordsToLoc(row, col)) :"";
      model.sheet.sheetData.\data[row][col] = change;
      model.sheet.comments = removeComment(model.sheet.comments, row, col);
    }
    catch ParseError(loc location):{
      println("Parse error in cell (<row>,<col>): <location> with change: <change>");
      model.sheet.comments = replaceComment(model.sheet.comments, row, col, "ParseError(<location>)", parseerror());
      model.sheet.sheetData.\data[row][col] = highlightErrorSubstring(change, location.begin.column,location.end.column);
    }
    return model;
}

// Remove all previous errors and replace them with new set of errors, should not be called when there are stil parse errors
Model replaceErrors(set[Message] errs, Model model, bool structuralerr = false){
  list[CommentData] tempComments = []; 
  // Reset all highlights of previous errors
  for (CommentData c <- model.sheet.comments) {
    model.sheet.sheetData.\data[c.row][c.col] = model.parsedData.raw[c.row][c.col];
  }
  for (Message err <- errs){
    CommentData ans = messageToCommentData(err, structuralerr ? structuralerror() : err is warning ? warning() : error());
    tempComments += ans;
    model.sheet.sheetData.\data[ans.row][ans.col] = highlightErrorSubstring(model.parsedData.raw[ans.row][ans.col], err.at.begin.column,err.at.end.column);
  }
  model.sheet.comments = tempComments;
  return model;
}

// Parse the full sheet, checking for missing cells and semantic errors
Model parseFullSheet(Model model) {
    set[Message] errs = checkRequiredBlocks(model.parsedData.raw, model.s);
    bool missingCells = size(errs) > 0;

    if (!missingCells && model.parseFunc != nothing())
      errs = model.parseFunc.val(parseMatrix(model.parsedData.parsed, model.s));

    return replaceErrors(errs, model, structuralerr=missingCells);
}


// Update the model based on the message received. 
// If a cell is changed, parse the change based on the grammar, and depending on if autoParse is enabled, parse the full sheet.
// If the parseSheet message is received, parse the full sheet and update the comments accordingly. Run the runFunc if it is set.
Model update(Msg msg, Model model){
  switch (msg){
    case sheetEdit(map[str,value] diff):{
      visit (diff["payload"]) {
        case "object"(col=int col, change=change, row=int row):{
          model = parseChanges(row, col, change, model);
        }
      }
      if (model.autoParse && (0 | it + 1 | commentData(_,_,_, parseerror()) <- model.sheet.comments) == 0) {
        model = parseFullSheet(model);
      }
    }
    case parseSheet():{
      model = parseFullSheet(model);
    }
    case runSheet():{
      if (model.runFunc != nothing()) 
        model.runFunc.val(parseMatrix(model.parsedData.parsed, model.s));
    }
  }
  return model;
}

// Run the handsontable spreadsheet view with the given model.
// onSheetChange specifies what message should be returned when a cell is changed.
void view(Model m) {
    spreadsheet(
      m.sheet,
      m.name,
      onSheetChange(sheetEdit)
    );
}


