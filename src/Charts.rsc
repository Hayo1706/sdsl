module Charts

import salix::HTML;
import salix::Node;
import salix::Core;
import lang::json::IO;

import salix::App;
import salix::Index;

import Map;
import IO;
import Set;
import String;

private str HANDSONTABLE_SRC = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/dist/handsontable.full.js";
private str HANDSONTABLE_CSS = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/styles/handsontable.min.css";
private str HANDSONTABLE_THEME = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/styles/ht-theme-main.min.css";

str initcode(str name, int length, str colheaders) = "
    '
    'function debounce(func, delay) {
    '  let timeout;
    '  return function(...args) {
    '    clearTimeout(timeout);
    '    timeout = setTimeout(() =\> {
    '      func.apply(this, args);
    '    }, delay);
    '  };
    '}
    '
    'const dChange = debounce(sendAllData, 300);
    'var container = document.getElementById(\'<name>_spreadsheet\');
    'hot = new Handsontable(container, {
    '  data: [[]],
    '  minSpareRows: 10,
    '  minCols: <length>,
    '  rowHeaders: true,
    '  themeName: \'ht-theme-main-dark\',
    '  manualColumnResize: true,
    '  manualRowResize: true,
    '  contextMenu: true,
    '  comments: {displayOnHover: true, readOnly: true},
    '  stretchH: \'all\',
    '  colHeaders: <colheaders>,
    '  afterChange: function(changes, source) {
    '    if (!<name>_pauseupdate) {
    '      changes?.forEach((element) =\> {
    '        let row = element[0];
    '        if (row \> <name>_lastrow) {
    '          <name>_lastrow = row;
    '        }
    '        sendChangedData(element);
    '        //dChange(hot);
    '      });
    '      
    '    }
    '  },
    '  licenseKey: \'non-commercial-and-evaluation\'
    '});
    '
    'window.hotInstance = hot;
    '
    '
    'function resetComments(){
    '  console.log(\'Setting comments\');
    '  for (let row = 0; row \< <name>_lastrow + 1; row++) {
    '    for (let col = 0; col \< hot.countCols(); col++) {
    '      const cellMeta = hot.getCellMeta(row, col);
    '      delete cellMeta.comment;
    '    }
    '  }
    '}
    '$salix.registerAlien(\'<name>\', p =\> <name>_patch(hot, p), {
    '  sheetSetMessage_<name>: args =\> {
    '    if (args.reset)
    '      resetComments();
    '    <name>_pauseupdate = true;
    '    console.log(args);
    '    for(let i = 0; i \< args.comments.length; i++) {
    '       console.log(args.comments[i].row);
    '       hot.getCellMeta(args.comments[i].row, args.comments[i].column).comment =  { value:args.comments[i].message};
    '       console.log(\'test\');
    '    }
    '    hot.render();
    '    <name>_pauseupdate = false;
    '    return {type: \'nothing\'};
    '  }
    '});
    '
    'console.log(\'Hot instance registered\');
    ";

Cmd sheetSetMessage(str name, Msg msg, message)
  = command("sheetSetMessage_<name>", encode(msg), args = message);

Attr onSheetChange(Msg(map[str,value]) f) = event("edit",jsonPayload(f));

void spreadsheet(str name, int length, str colheaders, Attr event=null()) {
  div(class("salix-alien"), id(name), attr("onClick", initcode(name, length, colheaders)), () {
    script(src(HANDSONTABLE_SRC), \type("text/javascript"));
    link(\rel("stylesheet"), href(HANDSONTABLE_CSS));
    link(\rel("stylesheet"), href(HANDSONTABLE_THEME));

    script(
      "function <name>_patch(sheet, patch) {
      '  console.log(JSON.stringify(p));
      '}
      'function sendAllData(sheet){
      '  if (window.<name>_lastrow != -1 ) {
      '    let data = sheet.getData();
      '    let filtered = JSON.parse(JSON.stringify(data.slice(0, window.<name>_lastrow + 1)), (key, value) =\> value === null ? \"\": value)
      '    console.log(filtered);
      '    $salix.send(<asJSON(event.handler)>, filtered);
      '  }
      '}
      '
      'function sendChangedData(change){
      '  const result = JSON.parse(JSON.stringify(change), (key, value) =\> value === null ? \"\": value)
      '  if (result[2] !== result[3])
      '    $salix.send(<asJSON(event.handler)>,result);
      '}
      '
      'window.<name>_lastrow = -1;
      'window.<name>_pauseupdate = false;
      'window.hotInstance = null;
      '
      ';");
      div(style(("width": "90vw", "height": "90vh")), id("<name>_spreadsheet"));
  });
}