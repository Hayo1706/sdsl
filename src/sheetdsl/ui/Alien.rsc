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

// The initcode function generates the JavaScript code that initializes the Handsontable instance with the given sheet data and name.
str initcode(SpreadSheet sheet, str name) = "
    'function debounce(fn, delay=300, limit = 80) {
    '  const te = new TextEncoder();
    '  let buf = [], timer;
    '
    'function flush() {
    '   if (!buf.length) return;
    '   fn(buf.slice());
    '   buf.length = 0;
    '}
    'return change =\> {
    '   if (buf.length \> limit) flush();
    '   buf.push(change);
    '   clearTimeout(timer);
    '   timer = setTimeout(flush, delay);
    '};
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
    '  rowHeaders: <sheet.enableRowHeaders>,
    '  renderAllColumns : true,
    '  themeName: \'ht-theme-main\',
    '  fixedColumnsStart: 0,
    '  fixedRowsTop: 0,
    '  manualColumnResize: true,
    '  manualRowResize: true,
    '  contextMenu: true,
    '  colWidths:<sheet.colWidths>,
    '  rowHeights: <sheet.rowHeights>,
    '  comments: {displayOnHover: true, readOnly: true},
    '  afterChange: function(changes, source) {
    '    const changedValues = [];
    '    changes?.forEach((element) =\> {
    '      if (element[2] === null) element[2] = \'\';
    '      if (element[3] === null) element[3] = \'\';
    '      if (element[2] == element[3]) return;
    '      sendBufferedChanges({
    '        row: element[0],
    '        col: element[1],
    '        change: element[3].replace(Regex_strip, \'\')
    '      });
    '        
    '    });
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
    // The Handsontable instance is initialized with the given sheet data, and the name is used to register the alien.
    div(class("salix-alien"), id(name), attr("onClick", initcode(sheet, name)), () {
      println(sheet.sheetData);
      script(src(HANDSONTABLE_SRC), \type("text/javascript"));
      link(\rel("stylesheet"), href(HANDSONTABLE_CSS));
      link(\rel("stylesheet"), href(HANDSONTABLE_THEME));
      // The patch function is used to update the Handsontable instance with new data when a patch is received. 
      // It updates the data of the spreadsheet to include error highlighting and comments in the Handsontable instance.
      script(
        "function <name>_patch(patch) {
        '  console.log(patch);
        '  let x = patch.edits[0].extra;
        '  if (patch.edits[0].extra.colIdOrder){
        '    window.<name>_hotInstance.updateSettings({columns: x.colIdOrder.map(id =\> ({ data: String(id) }))});
        '  }
        '  window.<name>_hotInstance.updateData(x.sheetData.data);
        '  window.<name>_hotInstance.updateSettings({
        '     cell: x.comments,
        '     colHeaders: x.sheetData.columnHeaders,
        '     rowHeaders: x.sheetData.rowHeaders,
        '  });

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