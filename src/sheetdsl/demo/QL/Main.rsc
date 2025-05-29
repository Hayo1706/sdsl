module sheetdsl::demo::QL::Main

import sheetdsl::demo::QL::App;
import sheetdsl::demo::QL::Definitions;
import sheetdsl::demo::QL::Check;

import sheetdsl::ParserSDSL;
import sheetdsl::ui::SheetWithToolbar;
import sheetdsl::Syntax;
import sheetdsl::util::Node2adt;

import util::Maybe;
import ParseTree;
import Node;
import IO;
import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;
import Content;
import util::Webserver;
import Exception;
import util::IDEServices;

App[Model] main() {
    start[SDSL] parsed = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/QL/QL.sdsl|);
    return initToolBar("TaxExample", parsed, parseFunc=just(parse2), runFunc=just(run2));
}

set[Message] parse2(list[node] nodes) {
    if (size(nodes) == 0) {
        return {};
    }
    return check(node2adt(nodes[0], #Forms));
}

void run2(list[node] nodes) {
    println("\nConverting node to adt...\n");
    if (Forms f := node2adt(nodes[0], #Forms)){
        showInteractiveContent(runQL(f));
    }
}