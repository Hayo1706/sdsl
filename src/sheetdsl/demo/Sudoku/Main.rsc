module sheetdsl::demo::Sudoku::Main

import sheetdsl::ParserSDSL;
import sheetdsl::SheetApp;
import sheetdsl::Syntax;
import sheetdsl::util::SyntaxReader;
import sheetdsl::util::Error;
import sheetdsl::SpreadSheets;

import util::Maybe;
import ParseTree;
import Node;
import IO;
import salix::HTML;
import salix::App;
import salix::Core;
import String;
import Set;

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



App[Model] main() {
    start[MGL] parsed = parse(#start[MGL], |project://sdsl/src/sheetdsl/demo/Sudoku/sudoku.mgl|);
    return initSheetWebApp("Sudoku", parsed, 
        spreadSheet(
            sheetData=spreadSheetData(sudokuDefaults),
            rowHeights=50, 
            colWidths=50, 
            enableColHeaders=false, 
            enableRowHeaders=false
        ), 
        semanticFunc=just(parseSudoku), extraCss=["sheetdsl/demo/Sudoku/sudoku.css"]);
}

set[Message] parseSudoku(list[node] nodes) {
    //Construct the grid from the nodes
    list[list[Maybe[Int]]] grid = [ [ i | Maybe[Int] i <-[m[k] | k <- m] ] | m <-[getKeywordParameters(n) | n <-nodes] ];
    set[Message] msgs = {};
    int N = size(grid);
    
    // Check if all the starting values are unchanged
    for (int r <- [0..N]) {
        for (int c <- [0..N]) {
            if (sudokuDefaults[r][c] == "" || grid[r][c] == nothing()) continue;
            if (sudokuDefaults[r][c] != "<grid[r][c].val>") 
                msgs += error("Starting value <sudokuDefaults[r][c]> cannot be changed", CoordsToLoc(r, c,begin=0, end = size("<grid[r][c].val>")));
        }
    }
    if (size(msgs) > 0) return msgs;
    
    for (int r <- [0..N]){
        for (int c <- [0..N]) {
            Maybe[Int] mv = grid[r][c];
            if (mv == nothing()) continue;
            
            int mvVal = toInt("<mv.val>");
            int r0 = (r / 3) * 3; // The starting row of the block
            int c0 = (c / 3) * 3; // The starting column of the block
            //For each cell in the, row, col, or block
            for (int cc <- [0..N]) {
                //Same row
                if (cc != c && grid[r][cc] != nothing() && toInt("<grid[r][cc].val>") == mvVal) 
                    msgs += warning("Duplicate value <mvVal> in row at (<r+1>, <c+1>)", mv.val.src);
                //Same column
                if (cc != r &&  grid[cc][c] != nothing() && toInt("<grid[cc][c].val>") == mvVal) 
                    msgs += warning("Duplicate value <mvVal> in column at (<r+1>, <c+1>)", mv.val.src);
                //Same block
                int br = r0 + (cc % 3);
                int bc = c0 + (cc / 3);
                if (c != bc && r != br && grid[br][bc] != nothing() && toInt("<grid[br][bc].val>") == mvVal)
                    msgs += warning("Duplicate value <mvVal> in block at (<r+1>, <c+1>)", mv.val.src);
            }
        }
    }
    return msgs;
}




