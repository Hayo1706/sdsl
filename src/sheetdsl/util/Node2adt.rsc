module sheetdsl::util::Node2adt

import Node;
import util::Maybe;
import ParseTree;
import Type;
import List;
import Set;
import Map;

// Check if the type of the node parameter matches the type of the constructor argument 
// Because the we convert from node to adt, we cant always just check if they are the same types. \adt(_,_) != \node()
// These can also be wrapped in lists or Maybe, so we need to check for that as well
private bool simmilarType(nodeType, argType) {
    if (\adt("Maybe", [args1]) := nodeType && \adt("Maybe", [args2]) := argType){
        // If the node is nothing() we have to assume that it is correct
        if (\void() := args1)
            return true;
        return simmilarType(args1, args2);
    }

    if (\list(args1) := nodeType && \list(args2) := argType)
        return simmilarType(args1, args2);

    if (\node() := nodeType && \adt(_,_) := argType)
        return true;

    if (nodeType == argType)
        return true;
    return false;
}

private tuple[str name, bool multiple, bool optional] isAdt(argType, bool multiple = false, bool optional = false) {
    if (\adt("Maybe", [args]) := argType)
        return isAdt(args, multiple=multiple, optional=true);

    if (\list(args) := argType)
        return isAdt(args, multiple=true, optional=optional);

    if (\adt(argName,_) := argType)
        return <argName, multiple, optional>;

    return <"", false, false>;
}

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
            continue constructors;

        //Check if the constructor has the same names and types as the node
        arguments: for (label(argName, argType) <- args){
            //Check if node param exists in the given type as constructor argument
            if (!params[argName]? || !simmilarType(typeOf(params[argName]), argType))
                continue constructors;
        }
        //Construct the arguments for the constructor
        list[value] vals = [];
        for (label(name, argType) <- args){
            //Check if column is a subblock
            isadt = isAdt(argType);
            if (isadt[0] == "" || params[name] == nothing()) //If the type is not an adt, we can just use the value
                vals += params[name];
            else {
                if (isadt.multiple && list[node] children := params[name] || just(list[node] children) := params[name]) {
                    subVals = [node2adt(n1, type(adt(isadt.name,[]),t.definitions)) | node n1 <- children];
                    vals += isadt.optional? just(subVals) : [subVals];
                }
                else {
                    subVals = node2adt(params[name], type(adt(isadt.name,[]),t.definitions));
                    vals += isadt.optional? just(subVals) : subVals;
                }
            }
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