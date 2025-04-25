module Stop

import ParseTree;
import IO;  
import Type;
import Map;
import Syntax;


void main() {
    start[SDSL] testing = parse(#start[SDSL], |project://sdsl/src/test.sdsl|);
    //find all optional instances and print their block and name
    map[str, list[str]] optionalInstances = ();
    for (Block b <- testing.questions){
        list[str] optional = [];
        for (Element e <- b.elems){
            if (/\*?\?=/ := "<e>"){
                optional += "<e.name>";
            }
            
        }
        optionalInstances["<b.name>"] = optional;
    }
    println(optionalInstances);

}



