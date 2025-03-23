module testing

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;
import salix::Node;

import util::Math;
import List;
import IO;

import String;
import ParseTree;
import lang::json::IO;


data Msg
  = sheetEdit(map[str,value] newValues)
  | testing2()
  | myClick(value v1, value v2)
  | myClick2(value v1, value v2)
  | myClick3(value v1, value v2)
  | myClick4(value v1, value v2);

Hnd targetValues(Msg(value,value) vals2msg) = handler("targetValues", encode(vals2msg));

void printEvent(){
    println("<asJSON(handler("targetValues", encode(myClick2)))>");
    println("<asJSON(handler("targetValues", encode(myClick4)))>");
    onClick(testing2).handler;

}