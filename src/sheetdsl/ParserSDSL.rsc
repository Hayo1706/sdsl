
module sheetdsl::ParserSDSL

import sheetdsl::Syntax;
import sheetdsl::util::SyntaxReader;
import sheetdsl::util::Error;
import Node;
import IO;
import List;
import Set;
import Map;
import vis::Text;
import Message;
import util::Math;
import util::Maybe;
import ParseTree;
import Type;


alias Matrix = list[list[value]];

bool isEmptyRow(list[value] row, int colStart = 0, int colEnd = size(row)){
    for (int i <- [colStart..colEnd]) {
        if (row[i] != "") {
            return false;
        }
    }
    return true;
}

private int getNextBlockInstance(Matrix m, int rowStart, Block b, int colStart){
    for(int r <- [rowStart+1..size(m)]){
        int colIdx = colStart;
        for (Element column <- b.elems){
            if(column is col && column.assign is required){
                if (m[r][colIdx] != "") return r;
            }
            colIdx += 1;
        }
    }
    return size(m);
}

private int countColumnsInBlock(Block b, map[str, Block] blocks) {
    int colCount = 0;
    for (Element column <- b.elems) {
        if (column is col) 
            colCount += 1;
        else
            colCount += countColumnsInBlock(blocks["<column.subBlock.name>"], blocks);
    }
    return colCount;
}

public set[Message] checkRequiredBlocks(Matrix m, start[SDSL] s) = checkRequiredBlock(m, s.top.topBlock, 0, size(m), 0, getBlocks(s))[0];
private tuple[set[Message] messages, bool empty] checkRequiredBlock(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
    set[Message] messages = {};
    bool empty = true;
    int row = startRow;
    while (row < endRow){
        int colIdx = colStart;
        int nextRow = row + 1;
        if (isEmptyRow(m[row])){
            row += 1;
            continue;
        }
        for (Element column <- b.elems){
            if(column is col){
                if (m[row][colIdx] == ""){
                    if (column.assign is required) messages += error("Cell is required but empty", CoordsToLoc(row,colIdx));
                } else {
                    empty = false;
                }
                colIdx += 1;
            }
            else if(column is sub){
                if ("<column.multiple>" == "*")
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart));

                tuple[set[Message], bool] newMessages = checkRequiredBlock(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                if (column.assign is required || !newMessages[1])
                    messages += newMessages[0];
            
                colIdx += countColumnsInBlock(blocks["<column.subBlock.name>"], blocks);
            }
        }
        row = nextRow;
    }
    return <messages, empty>;
}

Matrix removeEmptyRows(Matrix m) = [l | list[value] l <- m, !isEmptyRow(l)];

public list[node] parseMatrix(Matrix m, start[SDSL] s) {
    filtered = removeEmptyRows(m);
    return parseM(filtered, s.top.topBlock, 0, size(filtered), 0, getBlocks(s));
} 

private list[node] parseM(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
    list[node] instances = [];
    int row = startRow;
    while (row < endRow){
        int colIdx = colStart;
        int nextRow = row + 1;
        map[str, value] vals = ();
        for (Element column <- b.elems){
            value raw = nothing();
            if(column is col){
                if (m[row][colIdx] != "")
                    raw = m[row][colIdx];

                colIdx += 1;
            }
            else if(column is sub){
                if ("<column.multiple>" == "*")
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart));

                list[node] subInstances = parseM(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                if (subInstances != [])
                    raw = "<column.multiple>" == "*" ? subInstances : subInstances[0];

                colIdx += countColumnsInBlock(blocks["<column.subBlock.name>"], blocks);
            }
            // Wrap raw in just if optional (Dont need to wrap if its already nothing())
            vals["<column.name>"] = column.assign is required || raw == nothing() ? raw : just(raw);
        }
        row = nextRow;
        if((true | it && (vals[val] == "" || vals[val] == nothing()) | val <- vals))
            continue; // Skip empty rows
        instances += makeNode("<b.name>",keywordParameters=vals);
    }
    return instances;
}
