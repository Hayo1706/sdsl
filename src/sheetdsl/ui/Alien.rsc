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

str initcode(SpreadSheet sheet, str name) = "
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
    'const Regex_strip = /\<\\/?(?:pre|span)\\b[^\>]*\\b(?:id\\s*=\\s*([\\x27\\x22])hltx\\1)?[^\>]*\>/gi;
    'class CustomEditor extends Handsontable.editors.TextEditor {
    ' setValue(newValue) {
    '  this._original = newValue;
    '  this._strippedValue = newValue?.replace(Regex_strip, \'\')?.trim() ?? \'\';
    '  this.TEXTAREA.value = this._strippedValue;
    ' }
    ' focus() {
    '   super.focus();
    '   this.TEXTAREA.select();
    ' }
    ' getValue() {
    '   let value = this.TEXTAREA.value;
    '   if (value == this._strippedValue) return this._original;
    '   return value.replace(Regex_strip, \'\').trim();
    ' }
    '}
    'hot = new Handsontable(document.getElementById(\'<name>_spreadsheet\'), {
    '  maxCols: <size(sheet.sheetData.columnHeaders)>,
    '  rowHeaders: <sheet.enableRowHeaders>,
    '  renderAllColumns : true,
    '  themeName: \'ht-theme-main-dark\',
    '  fixedColumnsStart: 0,
    '  fixedRowsTop: 0,
    '  manualColumnResize: true,
    '  manualRowResize: true,
    '  contextMenu: true,
    '  colWidths:<sheet.colWidths>,
    '  rowHeights: <sheet.rowHeights>,
    '  comments: {displayOnHover: true, readOnly: true},
    '  colHeaders: <sheet.enableColHeaders ? replaceAll("<sheet.sheetData.columnHeaders>","\"","\'"): false>,
    '  afterChange: function(changes, source) {
    '    const changedValues = [];
    '    changes?.forEach((element) =\> {
    '      if (element[2] === null) element[2] = \'\';
    '      if (element[3] === null) element[3] = \'\';
    '      if (element[2] == element[3]) return;
    '      changedValues.push({
    '        row: element[0],
    '        col: element[1],
    '        change: element[3].replace(Regex_strip, \'\')
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

void spreadsheet(SpreadSheet sheet, str name, Attr event){
  withExtra(("sheet": sheet), (){
    div(class("salix-alien"), id(name), attr("onClick", initcode(sheet, name)), () {
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