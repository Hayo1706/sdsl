module sheetdsl::demo::Sudoku::Main

import sheetdsl::ParserSDSL;
import sheetdsl::ui::SheetWithToolbar;
import sheetdsl::Syntax;
import sheetdsl::util::SyntaxReader;
import sheetdsl::SpreadSheets;

import util::Maybe;
import ParseTree;
import Node;
import IO;
import salix::HTML;
import salix::App;
import salix::Core;
import String;

syntax Int = [0-9];

Matrix sudokuDefaults = [
  ["",  "5", "",  "",  "",  "8", "2", "",  "3"],
  ["3", "9", "",  "",  "4", "",  "7", "8", "6"],
  ["6", "8", "7", "2", "",  "",  "",  "",  "4"],
  ["",  "",  "",  "",  "",  "",  "8", "",  "" ],
  ["",  "4", "8", "",  "2", "",  "5", "",  "1"],
  ["1", "3", "",  "",  "7", "",  "",  "6", "" ],
  ["5", "2", "3", "4", "",  "1", "6", "",  "" ],
  ["8", "1", "4", "",  "",  "",  "3", "2", "" ],
  ["",  "7", "",  "3", "5", "",  "4", "",  "8"]
];



App[ToolBarModel] main() {
    start[SDSL] parsed = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/Sudoku/sudoku.sdsl|);
    println("Parsed");
    return initToolBar("Sudoku", parsed, 
        sheet=spreadSheet(
            sheetData=spreadSheetData(9, sudokuDefaults),
            rowHeights=50, 
            colWidths=50, 
            enableColHeaders=true, 
            enableRowHeaders=false
        ), 
        parseFunc=just(parse2), extraCss=["/sheetdsl/demo/Sudoku/sudoku.css"]);
}

set[Message] parse2(list[node] nodes) {
    list[list[Maybe[Int]]] grid = [];
    for (node n <- nodes) {
        list[Maybe[Int]] vals = [];
        params = getKeywordParameters(n);
        for (k <- params) {
            vals += params[k];
        }
        grid += [vals];
    }
    
    set[Message] msgs = {};
    int N = size(grid);           // 9 voor een standaard sudoku
    
    for (int r <- [0..N-1])
        for (int c <- [0..N-1]) {
            Maybe[Int] mv = grid[r][c];
            if (mv == nothing())           // lege cel: niks te controleren
                continue;
            
            int mvVal = toInt("<mv.val>");

            int r0 = (r / 3) * 3;
            int c0 = (c / 3) * 3;

            for (int cc <- [0..N-1]) {
                testing = grid[r][cc];

                //Same row
                if (cc != c && grid[r][cc] != nothing() && toInt("<grid[r][cc].val>") == mvVal) 
                    msgs += warning("Duplicate value <mvVal> in row at (<r+1>, <c+1>)", mv.val.src);

                //Same column
                if (cc != r &&  grid[cc][c] != nothing() && toInt("<grid[cc][c].val>") == mvVal) 
                    msgs += warning("Duplicate value <mvVal> in column at (<r+1>, <c+1>)", mv.val.src);

                //Same block
                if (c != c0 + (cc / 3) && r != r0 + (cc % 3) && grid[r0 + (cc % 3)][c0 + (cc / 3)] != nothing() && 
                    toInt("<grid[r0 + (cc % 3)][c0 + (cc / 3)].val>") == mvVal)
                    msgs += warning("Duplicate value <mvVal> in block at (<r+1>, <c+1>)", mv.val.src);

            }
      }

    return msgs;
}




