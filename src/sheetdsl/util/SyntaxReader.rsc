module sheetdsl::util::SyntaxReader

import sheetdsl::Syntax;
import sheetdsl::ParserSDSL;
import Map;

// This module provides utilities to read and extract information from the syntax tree of MGL.

// get all the blocks in the MGL syntax tree, indexed by their name.
map[str, Block] getBlocks(start[MGL] s){
    map[str, Block] blocks = ();
    visit(s){
        case Block b:{
            blocks["<b.name>"] = b;
        }
    }
    return blocks;
}

// Get the Elements from the MGL syntax tree, in order from left to right
list[Element] getSheetColumns(start[MGL] s, Block block = s.top.topBlock, map[str, Block] blocks = getBlocks(s)){
    list[Element] columns = [];
    for (Element e <- block.elems){
        if (e is col)
            columns += e;
        else if (e is sub){
            columns += getSheetColumns(s, block=blocks["<e.subBlock.name>"], blocks=blocks);
        }
    }
    return columns;
}

// Get the labels of the columns in the MGL syntax tree, in order from left to right, but as plain strings
list[str] getSheetLabels(start[MGL] s) = ["<e.column.header>"[1..-1] | Element e <- getSheetColumns(s)]; 
