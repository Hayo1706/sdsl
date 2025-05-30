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

private str TABULATOR_JS   = "https://unpkg.com/tabulator-tables@6.3.1/dist/js/tabulator.min.js";

str initcode(SpreadSheet sheet, str name) = "
    'function debounce(func, delay) {let t;let b = []; return function(args) {b.push(...args);clearTimeout(t);t = setTimeout(() =\> {func(b);b = [];}, delay);};}
    'const sendBufferedChanges = debounce(<name>_sendChangedData, 300);
    'const strip = v =\> (v ?? \'\').replace(/\<\\/?(?:pre|span)\\b[^\>]*\\b(?:id\\s*=\\s*([\\x27\\x22])hltx\\1)?[^\>]*\>/gi, \'\').trim();
    'const getColIndex = (col) =\> <replaceAll("<sheet.sheetData.columnHeaders>","\"","\'")>.indexOf(col);
    'var cleanTextEditor = function(cell,onRendered,success,cancel, editorParams){
    '  const raw  = cell.getValue();
    '  const base = strip(raw);
    '  const inp  = document.createElement(\'textarea\');
    '  inp.value  = base;
    '  inp.classList.add(\'tabulator-textarea\');
    '  onRendered(()=\>{inp.focus();});
    '  function done(){success(inp.value===base?raw:inp.value);}
    '  inp.addEventListener(\'keydown\',e=\>e.key===\'Enter\'&&done());
    '  inp.addEventListener(\'change\', done);
    '  inp.addEventListener(\'blur\',done);
    '  inp.addEventListener(\'mousedown\',e=\>{
    '    e.stopImmediatePropagation(); // prevent Tabulator from selecting the cell when clicking on the textarea
    '  });
    '  return inp;
    '}
    '
    'window.<name>_comments = [];
    'const cols = (<replaceAll("<sheet.sheetData.columnHeaders>","\"","\'")>).map((t,i)=\>({
    '  title: t,
    '  field: \'c\'+i,
    '}));
    'hot = new Tabulator(document.getElementById(\'<name>_spreadsheet\'), {
    '  importFormat: \'array\',
    '  autoResize:false,
    '  dataLoader: false,
    '  rowHeight: <sheet.rowHeights>,          
    '  columns: cols,
    '  height: \'100%\',
    '  selectableRange:1,
    '  selectableRangeColumns:true,
    '  selectableRangeRows:true,
    '  selectableRangeClearCells:true,

    '  editTriggerEvent:\'dblclick\',
    '  clipboard:true,
    '  clipboardCopyStyled:false,
    '  clipboardCopyConfig:{
    '      rowHeaders:false,
    '      columnHeaders:false,
    '  },
    '  clipboardCopyRowRange:\'range\',
    '  clipboardPasteParser:\'range\',
    '  clipboardPasteAction:\'range\',
    '  headerVisible:<sheet.enableColHeaders>,
    '  <if (sheet.enableRowHeaders){> rowHeader:{formatter:\'rownum\', headerSort:false, hozAlign:\'center\'},<}>
    '  columnDefaults:{ 
    '    minWidth: 10,
    '    width: <sheet.colWidths>,
    '    widthGrow:0,
    '    widthShrink:0,
    '    editor: cleanTextEditor,
    '    editorParams: {selectContents:true},
    '    resizable: \'header\',
    '    headerSort:false,
    '    formatter:\'html\',
    '    tooltip:function(e, cell, onRendered){
    '      const comment = window.<name>_comments[cell.getRow().getPosition()-1]?.[getColIndex(cell.getColumn().getField())];    
    '      if (!comment) return;        
    '      var el = document.createElement(\'div\');
    '      el.classList.add(comment.className);
    '      el.innerText = comment.comment;
    '      return el; 
    '    }
    '  },
    '});
    '
    'hot.on(\'cellEdited\', function(cell){
    '      console.log(\'cellEdited\', cell.getRow().getPosition(), cell.getColumn().getField(), cell.getOldValue(), cell.getValue());
    '      if (cell.getValue() == cell.getOldValue()) return;
    '      if (cell.getValue() === \'\' && cell.getOldValue() === undefined) return;
    '      sendBufferedChanges([{
    '        row: cell.getRow().getPosition() - 1, // Tabulator rows are 1-based, but we want 0-based
    '        col: parseInt(cell.getColumn().getField().slice(1)),
    '        change: strip(cell.getValue())
    '      }]);
    '});
    '//hot.on(\'dataProcessed\', () =\> hot.redraw(true), {once:true});
    'const css = `.tabulator-cell.has-comment::after{content:\'\\\\f075\';font-family:\'Font Awesome 6 Free\';font-weight:900;color:#ffb300;position:absolute;top:4px;right:4px;font-size:11px}`;
    'document.head.insertAdjacentHTML(\'beforeend\',\'\<style\>\'+css+\'\</style\>\');
    '
    '$salix.registerAlien(\'<name>\', <name>_patch);
    'window.<name>_hotInstance = hot;
    ";

Attr onSheetChange(Msg(map[str,value]) f) = event("edit",jsonPayload(f));


// This alien requires the Tabulator css to be loaded in the HTML head seperately.
void spreadsheet(SpreadSheet sheet, str name, Attr event){
  withExtra(("sheet": sheet), (){
    div(class("salix-alien"), id(name), attr("onClick", initcode(sheet, name)), () {
      script(src(TABULATOR_JS), \type("text/javascript"));

      script(
        "function <name>_patch(patch) {
        '  console.log(\"patching\",patch);
        '  let x = patch.edits[0].extra;
        '  window.<name>_comments = x.comments;
        '  window.<name>_hotInstance.replaceData(x.sheetData.data);
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