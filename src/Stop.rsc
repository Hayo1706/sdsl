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
import lang::rascal::grammar::definition::Modules;

import util::Reflective;
import Map;
import Node;
import Set;
import Message;
import sheetdsl::ParserSDSL;
import sheetdsl::ui::SheetWithToolbar;
import sheetdsl::Syntax;
import sheetdsl::ui::SheetApp;
import IO;
import salix::App;

App[Model] main() {
    start[MGL] parsed = parse(#start[MGL], |project://sdsl/src/testing.mgl|);
    return initSheetWebApp("InvoiceTest", parsed, parseFunc=just(semanticChecks), rows=20);
}

set[Message] semanticChecks(list[node] nodes) {
    return {};
}
    