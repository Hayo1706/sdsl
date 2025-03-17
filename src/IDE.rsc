module IDE

import util::LanguageServer;
import util::Reflective;
import util::IDEServices;
import IO;
import ValueIO;
import List;
import salix::App;
import App;

import Syntax;
import Message;
import ParseTree;

set[LanguageService] myLanguageContributor() = {
    parser(Tree (str input, loc src) {
        return parse(#start[SDSL], input, src);
    }),
    lenses(myLenses),
    executor(myCommands)
};

data Command 
  = runSDSL(start[SDSL] sheet) 
  | compileSDSL(start[SDSL] sheet);

rel[loc,Command] myLenses(start[SDSL] sheet) = {
    <sheet@\loc, runSDSL(sheet, title="Run...")>,
    <sheet.src, compileSDSL(sheet, title="Compile")>
};

void myCommands(runSDSL(start[SDSL] sheet)) {
    showInteractiveContent(runWebSDSL(sheet));
}

void myCommands(compileSDSL(start[SDSL] sheet)) {
    println("Compiling SDSL");
}

void main() {
    registerLanguage(
        language(
            pathConfig(srcs = [|std:///|, |project://sdsl/src|]),
            "SDSL",
            "sdsl",
            "IDE",
            "myLanguageContributor"
        )
    );
}