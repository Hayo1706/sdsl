module sheetdsl::ui::Toolbar
import salix::HTML;
import salix::Node;

import IO;

void toolBar(str name, &t parseEvent, &t runEvent, bool canParse, bool canRun) {
    // div(style(("display":"inline-block", "gap":"2px")), () {
    //     importCSV(name);
    //     exportCSV(name);
    //     parsebtn(parseEvent, canParse);
    //     runbtn(runEvent, canRun);
    // });
}

str onClickBtnInit(str name) = "(function(){document.getElementById(\'<name>_import-file-input\').click();})();";

str importcsvJS(str name) = "
    'function <name>loadCsvIntoHot(file){
    '  Papa.parse(file, {
    '    worker:true, 
    '    header:false,
    '    skipEmptyLines:\'greedy\',
    '    dynamicTyping:true,
    '    complete: res =\> {
    '      const changes = [];
    '      res.data.forEach((row, r) =\> row.forEach((val, c) =\> {
    '         changes.push([r, c, \'\', val]);
    '      }));
    '      window.<name>_hotInstance.runHooks(\'afterChange\', changes, \'csv-import\');
    '    },
    '    error: err =\> alert(\'CSV‑error: \'+err.message)
    '  });
    '}
    'document.addEventListener(\'DOMContentLoaded\', (event) =\> {
    'document.getElementById(\'<name>_spreadsheet\').addEventListener(\'dragover\', e =\> {
    '  e.preventDefault();
    '  e.dataTransfer.dropEffect = \'copy\';
    '});
    'document.getElementById(\'<name>_spreadsheet\').addEventListener(\'drop\', e =\> {
    '  e.preventDefault();
    '  const file = e.dataTransfer.files[0];
    '  if (file) 
    '    loadCsvIntoHot(file);
    '});
    '});
";

str inputFunc(str name) = "
    '(function(evt) {
    '  const file = evt.target.files[0];
    '  if (file) {
    '    <name>loadCsvIntoHot(file);
    '  }
    '})(event);
";

private str PAPAPARSE_SRC = "https://cdn.jsdelivr.net/npm/papaparse@5.5.2/papaparse.min.js";

void importCSV(str name, str impCode = importcsvJS(name), str inputFun = inputFunc(name)) {
    script(src(PAPAPARSE_SRC), \type("text/javascript"));
    button(id("<name>_import-file"),attr("onClick",onClickBtnInit(name)),"Import csv");
    script(\type("text/javascript"),impCode);
    input(id("<name>_import-file-input"),attr("onchange",inputFun), \type("file"), accept(".csv"), style(("display":"none")));
}

str exportCode(str name) = "
    '(function(){
    '  window.<name>_hotInstance.getPlugin(\'exportFile\').downloadFile(\'csv\', {
    '    bom: false,
    '    columnDelimiter: \',\',
    '    columnHeaders: false,
    '    exportHiddenColumns: false,
    '    exportHiddenRows: false,
    '    fileExtension: \'csv\',
    '    filename: \'CSV-file_[YYYY]-[MM]-[DD]\',
    '    mimeType: \'text/csv\',
    '    rowDelimiter: \'\\r\\n\',
    '    rowHeaders: false,
    '  });
    '})();
";

void exportCSV(str name, str expCode = exportCode(name)) {
    button(id("<name>_export-file"),attr("onClick", expCode), "Export csv");
}

str parseOnCtrlS(str scope) = "
    'document.addEventListener(\'DOMContentLoaded\', (event) =\> {<scope>.addEventListener(\'keydown\', e =\> {
    '  const isSaveCombo = (e.ctrlKey || e.metaKey) && e.key === \'s\';
    '  if (isSaveCombo) {
    '    e.preventDefault();
    '    e.stopPropagation();
    '    console.log(\'Saving...\');
    '    document.getElementById(\'parseBtn\').click();
    '  }
    '})});;
";

void parsebtn(&t event, bool canParse, str saveScope = "document.getElementById(\'parseBtn\').parentElement.parentElement"){
    script(\type("text/javascript"),parseOnCtrlS(saveScope));
    button(id("parseBtn"),\onClick(event),disabled(!canParse),"Parse");
}

void runbtn(&t event, bool canRun) {
    button(id("runBtn"),\onClick(event),disabled(!canRun),"Run");
}