module sheetdsl::demo::QL::Main

import sheetdsl::demo::QL::App;
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
    return initSheetToolBar("TaxExample", parsed, getBasicSpreadSheet(parsed, 25), parseFunc=just(semanticChecks), runFunc=just(run), autoParse=true);
}

set[Message] semanticChecks(list[node] nodes) {

    if (size(nodes) == 0)
        return {};


    return check(node2adt(nodes[0], #Forms));
}

void run(list[node] nodes) {

    if (size(nodes) == 0)
        return;


    showInteractiveContent(runQL(node2adt(nodes[0], #Forms)));
}