module sheetdsl::demo::QL::Main

import sheetdsl::demo::QL::MultipleFormsApp;
import sheetdsl::demo::QL::Definitions;
import sheetdsl::demo::QL::Check;

import sheetdsl::ParserSDSL;
import sheetdsl::ui::SheetWithToolbar;
import sheetdsl::SheetApp;
import sheetdsl::Syntax;
import sheetdsl::util::Node2adt;

import util::Maybe;
import ParseTree;
import Node;
import salix::App;
import util::IDEServices;
import IO;
App[Model] main() {
    start[MGL] parsed = parse(#start[MGL], |project://sdsl/src/sheetdsl/demo/QL/QL.mgl|);
    return initSheetToolBar("TaxExample", parsed, getBasicSpreadSheet(parsed, 25), semanticFunc=just(semanticChecks), runFunc=just(run), autoSemantic=true);
}

set[Message] semanticChecks(list[node] nodes) {
    set[Message] messages = {};
    for (node n <- nodes) {
        messages += check(node2adt(n, #Forms));
    }
    return messages;
}

void run(list[node] nodes) {
    showInteractiveContent(runMultipleQL(node2adt(nodes, #Forms)));
}