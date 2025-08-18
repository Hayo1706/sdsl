
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

// This module provides the functionality to parse a matrix of values into a node tree.
// it also provides functionality to check for structusral errors in the matrix, such as missing required cells.
// The matrix is represented as a list of lists, where each inner list represents a row of values.

alias Matrix = list[list[value]];

// Check if a row is empty, i.e. all values in the row are empty strings.
bool isEmptyRow(list[value] row, int colStart = 0, int colEnd = size(row)){
    for (int i <- [colStart..colEnd]) {
        if (row[i] != "") {
            return false;
        }
    }
    return true;
}

// Check at which row the next instance of a block starts in the matrix.
private int getNextBlockInstance(Matrix m, int rowStart, Block b, int colStart, map[str, Block] blocks){
    for(int r <- [rowStart+1..size(m)]){
        int colIdx = colStart;
        for (Element column <- b.elems){
            if(column is col){
                if (m[r][colIdx] != "") return r;
                colIdx += 1;
            }
            else if(column is sub){
                colIdx += countColumnsInBlock(blocks["<column.subBlock.name>"], blocks);
            }
            
        }
    }
    return size(m);
}

// Count the number of columns in a block, including sub-blocks of the block.
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


// Main function to check for structural errors in the matrix.
// It checks if all required cells are filled in, and returns a set of messages indicating any structural errors found.

public set[Message] checkRequiredBlocks(Matrix m, start[MGL] s) = checkRequiredBlock(m, s.top.topBlock, 0, size(m), 0, getBlocks(s))[0];

// This function checks a range of rows in the matrix for structural errors. The first time it is called, it checks the entire matrix. When it recursively checks sub-blocks, it only checks the rows that are relevant for that sub-block.
private tuple[set[Message] messages, bool empty] checkRequiredBlock(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
    set[Message] messages = {};
    bool empty = true;
    int row = startRow;
    while (row < endRow){
        int colIdx = colStart;
        int nextRow = row + 1;
        // Skip empty rows
        if (isEmptyRow(m[row])){
            row += 1;
            continue;
        }
        // Check each column/sub-block in the block
        for (Element column <- b.elems){
            if(column is col){
                // Check if the cell is required and empty if so it adds a structural error message.
                if (m[row][colIdx] == ""){
                    if (column.assign is required) messages += error("StructuralError(Cell is required but empty)", CoordsToLoc(row,colIdx));
                } else {
                    empty = false;
                }
                colIdx += 1;
            }
            else if(column is sub){
                // If the column is a sub-block, it checks for the next instance of the sub-block.
                if ("<column.multiple>" == "*")
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart, blocks));
                // recursively checks the sub-block for structural errors, in the region from the current row to the next instance of the sub-block, from the current column index to the last column index of the sub-block.
                tuple[set[Message], bool] newMessages = checkRequiredBlock(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                // If the sub-block has structural errors, it adds them to the messages set.
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

// Parse the matrix into a tree of nodes
// First it removes empty rows from the matrix, then it calls the recursive function parseM to parse the matrix into nodes.
public list[node] parseMatrix(Matrix m, start[MGL] s) {
    filtered = removeEmptyRows(m);
    return parseM(filtered, s.top.topBlock, 0, size(filtered), 0, getBlocks(s));
} 

// Just like checkRequiredBlock it searches only in a section of the matrix, at first this is the whole matrix, but when it recursively checks sub-blocks, it only checks the rows that are relevant for that sub-block.
private list[node] parseM(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
    list[node] instances = [];
    int row = startRow;
    while (row < endRow){
        int colIdx = colStart;
        int nextRow = row + 1;
        map[str, value] vals = ();
        // go over all colmns/subblocks in the block
        for (Element column <- b.elems){
            // it assumes that the matrix doesnt have structural errors, so it does not check for empty cells, standard value is nothing(), which happens when an optional column is empty.
            value raw = nothing();
            // If the column is not empty, it just takes the value from the matrix.
            if(column is col){
                if (m[row][colIdx] != "")
                    raw = m[row][colIdx];

                colIdx += 1;
            }
            // If the column is a sub-block, it checks for the next instance of the sub-block. and recursively parses the sub-block for instances, returns another list of nodes.
            else if(column is sub){
                if ("<column.multiple>" == "*")
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart, blocks));

                list[node] subInstances = parseM(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                if (subInstances != [])
                    raw = "<column.multiple>" == "*" ? subInstances : subInstances[0];

                colIdx += countColumnsInBlock(blocks["<column.subBlock.name>"], blocks);
            }
            // Wrap raw in just if optional (Dont need to wrap if its already nothing()) and put it into a list which will be used to create the node.
            vals["<column.name>"] = column.assign is required || raw == nothing() ? raw : just(raw);
        }
        row = nextRow;
        if((true | it && (vals[val] == "" || vals[val] == nothing()) | val <- vals))
            continue; // Skip empty blocks
        instances += makeNode("<b.name>",keywordParameters=vals);
    }
    return instances;
}
