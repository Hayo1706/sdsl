module sheetdsl::util::Node2adt

import Node;
import util::Maybe;
import ParseTree;
import Type;
import List;
import Set;
import Map;

public value node2adt(list[node] n, type[&T] t) = [node2adt(n1, t) | node n1 <- n];
//Convert a node to a data type with the same names, types and values
public value node2adt(node n, type[&T] t) {
    params = getKeywordParameters(n);
    //Get all the constructors for the type
    choice(_,alts) = t.definitions[adt(getName(n),[])];
    //Loop over all the constructors
    constructors: for (c:cons(label(consName, _), args, _, _) <- alts){
        //Check if the constructor has the same amount of arguments as the node
        if (size(args) != size(params))
            continue;

        //Check if the constructor has the same names and types as the node
        for (label(lblName, ltype) <- args){
            typ = typeOf(params[lblName]);
            if (!params[lblName]? || (typ != ltype && typ != \list(\node()) && !(params[lblName] == nothing() && typ.name == "Maybe"))){
                continue constructors;
            }
        }
        //Construct the arguments for the constructor
        list[value] vals = [];
        for (label(name, lblType) <- args){
            //Check if column is a subblock
            if (\list(adt(adtName,[])):= lblType && list[node] children := params[name]){
                vals += [[node2adt(n1, type(adt(adtName,[]),t.definitions)) | node n1 <- children]];
            }
            else
                vals += params[name];
        }
        //Make the instance
        t = type(adt(getName(n),[]),t.definitions);
        return make(t, consName, vals);
    }

    str requiredParams = "";
    for (key <- params){
        requiredParams += "<typeOf(params[key])> <key>,";
    }
    throw "No valid constructor found for node <getName(n)>, expected <requiredParams>";
}