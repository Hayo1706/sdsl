module IDE

import util::LanguageServer;
import util::Reflective;
import util::IDEServices;

import sheetdsl::Syntax;
import Message;
import ParseTree;

set[LanguageService] myLanguageContributor() = {
    parser(Tree (str input, loc src) {
        return parse(#start[MGL], input, src);
    }),
    lenses(myLenses)
};

data Command 
  = runSDSL(start[MGL] sheet) 
  | compileSDSL(start[MGL] sheet);

rel[loc,Command] myLenses(start[MGL] sheet) = {
    <sheet@\loc, runSDSL(sheet, title="Run...")>,
    <sheet.src, compileSDSL(sheet, title="Compile")>
};


void main() {
    registerLanguage(
        language(
            pathConfig(srcs = [|std:///|, |project://sdsl/src|]),
            "MGL",
            "mgl",
            "IDE",
            "myLanguageContributor"
        )
    );
}