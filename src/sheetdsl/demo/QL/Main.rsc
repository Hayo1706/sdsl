module sheetdsl::demo::QL::Main

import sheetdsl::demo::QL::App;
import sheetdsl::demo::QL::Definitions;
import sheetdsl::demo::QL::Check;

import sheetdsl::ParserSDSL;
import sheetdsl::ui::SheetWithToolbar;
import sheetdsl::Syntax;

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
    start[SDSL] parsed = parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/QL/test.sdsl|);
    return init("TaxExample", parsed, parseFunc=parse2, runFunc=run2);
}

set[Message] parse2(list[node] nodes) {
    if (size(nodes) == 0) {
        return {};
    }
    return check(node2data(nodes[0], #Forms, parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/QL/test.sdsl|)));
}

void run2(list[node] nodes) {
    println("\nConverting node to adt...\n");
    if (Forms abc := node2data(nodes[0], #Forms, parse(#start[SDSL], |project://sdsl/src/sheetdsl/demo/QL/test.sdsl|))){
        println(abc);
        showInteractiveContent(runQL(abc));
    }
}