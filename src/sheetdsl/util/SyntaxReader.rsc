module sheetdsl::util::SyntaxReader

import sheetdsl::Syntax;
import sheetdsl::ParserSDSL;
import Map;

map[str, Block] getBlocks(start[SDSL] s){
    map[str, Block] blocks = ();
    visit(s){
        case Block b:{
            blocks["<b.name>"] = b;
        }
    }
    return blocks;
}

list[Element] getSheetColumns(start[SDSL] s, Block block = s.top.topBlock, map[str, Block] blocks = getBlocks(s)){
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

list[str] getSheetLabels(start[SDSL] s) = ["<e.column.header>"[1..-1] | Element e <- getSheetColumns(s)]; 
