module Stop

import ParseTree;
import IO;  
import Type;
import Map;
import sheetdsl::Syntax;
import sheetdsl::demo::QL::Definitions;
import Exception;
import util::Maybe;
import Grammar;
import lang::rascal::grammar::definition::Productions;
import lang::rascal::grammar::definition::Layout;
import lang::rascal::grammar::definition::Symbols;
import Map;
import Node;
import Set;
import Message;


data CellLoc  = CellLoc(str row, str col);
CellLoc locOf(str msg) {
    if (/<row:[0-9]+>,<col:[0-9]+>/ := msg)
        return CellLoc(row, col);
    return CellLoc("", "");
}

void main() {
    str rowStr = "11";
    str colStr = "10";
    str a = "cell://<rowStr>,<colStr>";
    CellLoc loca = locOf(a);
    println("Row <loca.row> Col <loca.col>");
}
    