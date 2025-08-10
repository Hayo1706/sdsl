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
import salix::App;
import util::IDEServices;
import util::Benchmark;
import IO;
App[Model] main() {
    start[MGL] parsed = parse(#start[MGL], |project://sdsl/src/sheetdsl/demo/QL/QL.mgl|);
    return initSheetToolBar("TaxExample", parsed, parseFunc=just(semanticChecks), runFunc=just(run), rows=10000);
}

set[Message] semanticChecks(list[node] nodes) {
    if (size(nodes) == 0)
        return {};
    timeSemanticStart = realTime();
    temp = check(node2adt(nodes[0], #Forms));
    timeSemanticEnd = realTime();
    println("Semantic checks took <timeSemanticEnd - timeSemanticStart> ms");
    return temp;
}

void run(list[node] nodes) {
    if (size(nodes) == 0)
        return;
    showInteractiveContent(runQL(node2adt(nodes[0], #Forms)));
    
}