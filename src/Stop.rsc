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

data Tesing = hallo(str val1 = "", str val2 = "");
data Tesing2 = hallo2(str val1 = "", str val2 = "");
void main() {
    start[SDSL] parsed = parse(#start[SDSL], |project://sdsl/src/testing.sdsl|);
    Module m = parseModule(|project://sdsl/src/sheetdsl/demo/QL/Definitions.rsc|);
    Grammar gr = module2grammar(m).grammar;
    println(gr);

    void(list[&T]) f = testFunc;

    //now get type of the list

    println(typeOf(f).parameters[0][0]);
    iprintln(f);
    map[str, value] vals = ();
    vals["val1"] = "Form1";
    vals["val2"] = "Name1";
    instances = makeNode("hallo",keywordParameters=vals);
    make(#Tesing, "hallo", [], vals);
    println(getChildren(instances));

}

void testFunc(list[Tesing2] t){
    println(t[0].val1);
    println(t[0].val2);
}
    