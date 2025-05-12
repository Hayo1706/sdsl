module sheetdsl::ui::Alien

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
import List;
import sheetdsl::SpreadSheets;

private str HANDSONTABLE_SRC = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/dist/handsontable.full.js";
private str HANDSONTABLE_CSS = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/styles/handsontable.min.css";
private str HANDSONTABLE_THEME = "https://cdn.jsdelivr.net/npm/handsontable@15.1.0/styles/ht-theme-main.min.css";

str initcode(str name, int length, str colheaders, int amountCols, &t rowHeights, &t colWidths) = "
    'function debounce(func, delay) {
    '  let timeout;
    '  let buffer = []; 
    '  return function(args) {
    '    console.log(args);
    '    buffer.push(...args);
    '    clearTimeout(timeout);
    '    timeout = setTimeout(() =\> {
    '      func(buffer);
    '      buffer = [];
    '    }, delay);
    '  };
    '}
    'const sendBufferedChanges = debounce(<name>_sendChangedData, 300);
    'class CustomEditor extends Handsontable.editors.TextEditor {
    ' setValue(newValue) {
    '  const strippedValue = newValue?.replace(/\<\\/?[^\>]*\\bid=\\x22hltx\\x22[^\>]*\>/g, \'\')?.trim() ?? \'\';
    '  this.TEXTAREA.value = strippedValue;
    ' }
    ' focus() {
    '   super.focus();
    '   this.TEXTAREA.select();
    ' }
    '}
    'hot = new Handsontable(document.getElementById(\'<name>_spreadsheet\'), {
    '  maxCols: <amountCols>,
    '  rowHeaders: true,
    '  renderAllColumns : true,
    '  themeName: \'ht-theme-main-dark\',
    '  fixedColumnsStart: 0,
    '  fixedRowsTop: 0,
    '  manualColumnResize: true,
    '  manualRowResize: true,
    '  contextMenu: true,
    '  colWidths:<colWidths>,
    '  rowHeights: <rowHeights>,
    '  comments: {displayOnHover: true, readOnly: true},
    '  colHeaders: <colheaders>,
    '  afterChange: function(changes, source) {
    '    const changedValues = [];
    '    changes?.forEach((element) =\> {
    '      if (element[2] === null) element[2] = \'\';
    '      if (element[3] === null) element[3] = \'\';
    '      if (element[2] == element[3]) return;
    '      changedValues.push({
    '        row: element[0],
    '        col: element[1],
    '        change: element[3].replace(/\<\\/?[^\>]*\\bid=\\x22hltx\\x22[^\>]*\>/g, \'\')
    '      });
    '        
    '    });
    '    if (changedValues.length != 0)
    '       sendBufferedChanges(changedValues, 300);
    '  },
    '  renderer: \'html\',
    '  licenseKey: \'non-commercial-and-evaluation\',
    '  editor: CustomEditor
    '});
    '$salix.registerAlien(\'<name>\', <name>_patch);
    'window.<name>_hotInstance = hot;
    ";

Attr onSheetChange(Msg(map[str,value]) f) = event("edit",jsonPayload(f));

void spreadsheet(SpreadSheet sheet, str name, Attr event, &t rowHeights = 30, &t colWidths = 120){
  withExtra(("sheet": sheet), (){
    div(class("salix-alien"), id(name), attr("onClick", initcode(name, size(sheet.sheetData.\data), replaceAll("<sheet.sheetData.columnHeaders>","\"","\'"), size(sheet.sheetData.columnHeaders), rowHeights, colWidths)), () {
      script(src(HANDSONTABLE_SRC), \type("text/javascript"));
      link(\rel("stylesheet"), href(HANDSONTABLE_CSS));
      link(\rel("stylesheet"), href(HANDSONTABLE_THEME));

      script(
        "function <name>_patch(patch) {
        '  console.log(\"patching\",patch);
        '  let x = patch.edits[0].extra;
        '  window.<name>_hotInstance.updateData(x.sheetData.data);
        '  window.<name>_hotInstance.updateSettings({cell: x.comments});
        '}
        '
        'function <name>_sendChangedData(change){
        '  $salix.send(<asJSON(event.handler)>,change);
        '}
        ';");
        div(id("<name>_spreadsheet"));
    });
  });
}