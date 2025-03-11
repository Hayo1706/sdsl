module Charts

import salix::HTML;
import salix::Node;
import salix::Core;
import lang::json::IO;

import Map;
import IO;
import Set;
import String;

private str HANDSONTABLE_SRC = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/dist/handsontable.full.js";
private str HANDSONTABLE_CSS = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/styles/handsontable.min.css";
private str HANDSONTABLE_THEME = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/styles/ht-theme-main.min.css";


alias SheetData = map[int,map[str,value]];
alias ColumnData = map[str,str];

alias Model = tuple[SheetData, ColumnData];


str dataValues(Model model){
  SheetData a = model[0];
  str dataconstant = "[";
  for(int row <- a){
    dataconstant += mapToString(a[row]);
  }
  dataconstant += "]";
  if (dataconstant == "[]")
    return "[[]]";
  return dataconstant;
}

str columnValues(Model model){
  ColumnData a = model[1];
  str columnconstant = "[";
  for(str name <- a){
    columnconstant += "{data: \"" + name + "\", type: \"" + a[name] + "\", className: \'htCenter htMiddle\'},";
  }
  columnconstant += "]";
  return columnconstant;
}

str mapToString(map[str,value] x){
  str result = "{";
  for(str key <- x){
    if (str string := x[key])
      result += key + ":" + "<x[key]>";
    else
      result += key + ":" + "<x[key]>"[1..-1];
  }
  result += "},";
  return result;
}

str escapeString(str x){
  return replaceAll(x, "\"", "\'");
}



str initcode(str name, Model model)= "
    'var container = document.getElementById(\'<name>_spreadsheet\');
    'console.log(container);
    'var hot = new Handsontable(container, {
    '  minRows: 110,
    '  minCols: 10,
    '  rowHeaders: true,
    '  themeName: \'ht-theme-main-dark\',
    '  manualColumnResize: true,
    '  manualRowResize: true,
    '  contextMenu: true,
    '  comments: {displayOnHover: true, readOnly: true},
    '  stretchH: \'all\',
    '  columns: <escapeString(columnValues(model))>,
    '  colHeaders: <escapeString("<toList(domain(model[1]))>")>,
    '  licenseKey: \'non-commercial-and-evaluation\'
    '});
    '
    '
    'window.hotInstance = hot;
    'console.log(\'init\');
    '<name>_init(hot);
    '
    '$salix.registerAlien(\'<name>\', p =\> <name>_patch(hot, p), {
    '  sheetSetMessage_<name>: args =\> {
    '    <name>_pauseupdate = true;
    '    hot.getCellMeta(args.row, hot.propToCol(args.column)).comment =  { value:args.message};
    '    hot.render();
    '    <name>_pauseupdate = false;
    '    return {type: \'nothing\'};
    '  },
    '
    '  sheetRemoveMessage_<name>: args =\> {
    '    <name>_pauseupdate = true;
    '    const cellMeta = hot.getCellMeta(args.row, hot.propToCol(args.column));
    '    delete cellMeta.comment;
    '    hot.render();
    '    <name>_pauseupdate = false;
    '    return {type: \'nothing\'};
    '  }
    '});
    '
    'console.log(\'Hot instance registered\');
";

Cmd sheetSetMessage(str name, Msg msg, row, column, message)
  = command("sheetSetMessage_<name>", encode(msg), args = ("row": row, "column": column, "message": message));

Cmd sheetRemoveMessage(str name, Msg msg, row, column)
  = command("sheetRemoveMessage_<name>", encode(msg), args = ("row": row, "column": column));

Attr onSheetChange(Msg(map[str,value]) f) = event("edit",jsonPayload(f));
Attr onRowCreate(Msg(int, int) m) = event("createrow",targetValues(m));
Attr onRowRemove(Msg(int, int) m) = event("removerow",targetValues(m));

Hnd targetValues(Msg(int, int) m) = handler("targetValues",encode(m));

void spreadsheet(str name, Model model, Attr change, Attr rowcreate, Attr rowremove) {
  println("spreadsheet");
  div(class("salix-alien"), id(name), attr("onClick", initcode(name, model)), () {
    script(src(HANDSONTABLE_SRC), \type("text/javascript"));
    link(\rel("stylesheet"), href(HANDSONTABLE_CSS));
    link(\rel("stylesheet"), href(HANDSONTABLE_THEME));

    script(
      "function <name>_patch(sheet, patch) {
      '  console.log(\"patch\");
      '}
      'function <name>_init(sheet){
      '  console.log(\"init\");
      '  sheet.updateSettings({
      '  afterChange: function(changes, source) {
      '      if (!<name>_pauseupdate) {
      '        let data = sheet.getData();
      '        console.log(data);
      '        changes?.forEach((element) =\> {
      '           const result = JSON.parse(JSON.stringify(element), (key, value) =\> value === null ? \"\": value)
      '           if (result[2] !== result[3])
      '             $salix.send(<asJSON(change.handler)>,result);
      '        });
      '      }
      '  },
      '  afterCreateRow: function(index, amount, source) {
      '    if (!<name>_pauseupdate) {
      '      console.log(\"row created\");
      '      $salix.send(<asJSON(rowcreate.handler)>,{value1: index, value2: amount});
      '    }
      '  },
      '  afterRemoveRow: function(index, amount, source) {
      '    if (!<name>_pauseupdate) {
      '      console.log(\"row removed\");
      '      $salix.send(<asJSON(rowremove.handler)>,{value1: index, value2: amount});
      '    }
      '  }
      '});
      '}
      '
      'window.<name>_pauseupdate = false;
      '
      ';");
      div(style(("width": "90vw", "height": "90vh")), id("<name>_spreadsheet"));
      
  });
}
