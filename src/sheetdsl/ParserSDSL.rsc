
module sheetdsl::ParserSDSL

import sheetdsl::Syntax;
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

int length(l) = (0| it + 1 | _ <- l);

loc CoordsToLoc(int row, int col){
    str coords = "<row>" + "," + "<col>";
    return |cell://<coords>|(0,0,<0,0>,<0,0>);
}

bool isEmptyRow(list[value] row, int colStart = 0, int colEnd = size(row)){
    for (int i <- [colStart..colEnd]) {
        if (row[i] != "") {
            return false;
        }
    }
    return true;
}

map[str, Block] getBlocks(start[SDSL] s){
    map[str, Block] blocks = ();
    visit(s){
        case Block b:{
            blocks["<b.name>"] = b;
        }
    }
    return blocks;
}

private int getNextBlockInstance(Matrix m, int rowStart, Block b, int colStart){
    for(int r <- [rowStart+1..size(m)]){
        int colIdx = colStart;
        for (Element column <- b.elems){
            if(column is col && column.assign is required){
                if (m[r][colStart] != "") return r;
            }
            colIdx += 1;
        }
    }
    return size(m);
}


public set[Message] checkRequiredBlocks(Matrix m, start[SDSL] s) = checkRequiredBlock(m, s.top.topBlock.b, 0, size(m), 0, getBlocks(s))[0];
private tuple[set[Message], bool] checkRequiredBlock(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
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
            if(column is col && column.assign is required){
                if (m[row][colIdx] == "") messages += error("Cell is required but empty", CoordsToLoc(row,colIdx));
                else empty = false;
                colIdx += 1;
            }
            else if(column is sub){
                if ("<column.multiple>" == "*")
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart));

                tuple[set[Message], bool] newMessages = checkRequiredBlock(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                if (column.assign is required){
                    messages += newMessages[0];
                }
                else if (column.assign is optional){
                    if (!newMessages[1]){
                        messages += newMessages[0];
                    }
                }
                colIdx += length(blocks["<column.subBlock.name>"].elems);
            }
        }
        row = nextRow;
    }
    return <messages, empty>;
}

Matrix removeEmptyRows(Matrix m) = [l | list[value] l <- m, !isEmptyRow(l)];

public list[node] parseMatrix(Matrix m, start[SDSL] s) {
    filtered = removeEmptyRows(m);
    return parseM(filtered, s.top.topBlock.b, 0, size(filtered), 0, getBlocks(s));
} 

private list[node] parseM(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
    list[node] instances = [];
    int row = startRow;
    while (row < endRow){
        int colIdx = colStart;
        int nextRow = row + 1;
        map[str, value] vals = ();

        for (Element column <- b.elems){
            if(column is col){
                if (column.assign is required){
                    vals["<column.name>"] = m[row][colIdx];
                }
                else { // Wrap in Maybe if optional
                    if (m[row][colIdx] != "") vals["<column.name>"] = just(m[row][colIdx]);
                    else vals["<column.name>"] = nothing();
                }
                colIdx += 1;
            }
            else if(column is sub){
                if ("<column.multiple>" == "*")
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart));
                vals["<column.name>"] = parseM(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                colIdx += length(blocks["<column.subBlock.name>"].elems);
            }
        }
        row = nextRow;
        instances += makeNode("<b.name>",keywordParameters=vals);
    }
    return instances;
}
