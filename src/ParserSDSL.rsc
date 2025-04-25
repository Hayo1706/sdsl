
module ParserSDSL
// layout WS = [\ \n\r]*;
syntax Bool = "true" | "false";
syntax Types = "string" | "int" | "bool";
syntax Int = [\-]?[0-9]+; 
syntax QName = "Question" Int;
syntax Expr
  = bracket "(" Expr ")"
  > Int | Bool | Str 
  > left ( Expr "&&" Expr
          | Expr "||" Expr 
          )
  ;

import Syntax;
import Node;
import IO;
import List;
import Map;
import util::Maybe;
import vis::Text;

import ParseTree;
import Type;

map[str, Block] blocks = ();
map[str, list[str]] optionalInstances = ();

alias Matrix = list[list[value]];

data Forms     = forms(Str name, list[Question] questions) | forms(list[Question] questions);
data Question  = question(Str question, Int maxlength, QName name, Maybe[Expr] \value, Types \type, Expr condition);



list[node] parseData(Matrix m, start[SDSL] s){
    blocks = getBlocks(s);
    optionalInstances = getOptionalInstances(s);

    list[Block] topLvlBlocks = getTopBlocks(s);

    if (size(topLvlBlocks) > 1)
        throw "Only one top-level-block supported for now";
    return scanBlock(m, topLvlBlocks[0], size(m));
}

// This makes some ssumptions: first rows are not empty. No empty rows between data. Only one type of top block.
list[node] scanBlock(Matrix m, Block b,int amountRows, int startRowIdx = 0, int startColIdx = 0){
    list[node] instances = [];
    int row = startRowIdx;
    // Only scans the rows that belong to this block
    while(row < amountRows){
        //Check if the whole row is empty or not, if so, return
        bool empty = true;
        for (int idx <- [startColIdx..size(m[row])]){
            if (m[row][idx] != ""){ 
                empty = false;
                break;
            }   
        }
        if (empty)
            return instances;
        int colIdx = 0;
        map[str, value] vals = ();
        //Go over all columns
        for(Element column <- b.elems){
            //Check if the column is a value type, or another subblock
            if (column is col)
                vals["<column.name>"] = m[row][startColIdx + colIdx];
            else if (column is sub){
                int nextBlock = calculateNextInstanceBlock(m,b,row,startColIdx);
                vals["<column.name>"] = scanBlock(
                    m,blocks["<column.subBlock.name>"],nextBlock, startRowIdx=row,startColIdx=startColIdx + colIdx
                );
                row = (nextBlock - 1); // Skip the rows of the subblock
            }
            colIdx += 1;
        }
        row += 1;
        instances += makeNode("<b.name>",keywordParameters=vals);
    }
    return instances;
}

int calculateNextInstanceBlock(Matrix m, Block b, int row, int col){
    for(int idx <- [row+1..size(m)]){
        if (reqColsFilled(m,b,idx,col)){
            return idx;
        }
    }
    return size(m);
}

map[str,list[str]] getOptionalInstances(start[SDSL] s){
    map[str, list[str]] optionalInstances = ();
    for (Block b <- s.top.questions){
        list[str] optional = [];
        for (Element e <- b.elems){
            if (/\*?\?=/ := "<e>"){
                optional += "<e.name>";
            }
            
        }
        optionalInstances["<b.name>"] = optional;
    }
    return optionalInstances;
}

bool reqColsFilled(Matrix m, Block b,int row,int colIdx){
    bool empty = true;
    for(Element column <- b.elems){
        //Pattern match to only columnms that are not optional
        if (column is col && !(/\*?\?=/ := "<column>")){
            if (m[row][colIdx] == ""){
                if (!empty){
                    throw "Block cannot be partially filled in";
                }
            }
            else {
                empty = false;
            }
        }
    }
    return !empty;
}

map[str,Block] getBlocks(start[SDSL] s){
    map[str, Block] blockMap = ();
    visit(s){
        case Block b:{
            blockMap["<b.name>"] = b;
        }
    }
    return blockMap;

}

list[Block] getTopBlocks(start[SDSL] s){
    list[str] allSubBlocks = [];
    visit(s){
        case SubBlock b:{
            allSubBlocks += "<b.name>";
        }
    }
    list[Block] topBlocks = [];
    visit(s){
        case Block b:{
            if (!("<b.name>" in allSubBlocks))
                topBlocks += b;
        }
    }
    return topBlocks;

}



public value node2data(list[node] n, type[&T] t, start[SDSL] s) = [node2data(n1, t, s) | node n1 <- n];

public value node2data(node n, type[&T] t, start[SDSL] s) = node2data(n, t, getOptionalInstances(s));

//Convert a node to a data type with the same names, types and values
public value node2data(node n, type[&T] t, map[str,list[str]] optional) {
    //Get all the constructors for the type
    choice(_,alts) = #Forms.definitions[adt(getName(n),[])];
    //Loop over all the constructors
    for (c:cons(label(consName, _), args, _, _) <- alts){
        //Check if the constructor has the same amount of arguments as the node
        if (size(args) != size(getKeywordParameters(n))){
            continue;
        }
        //Check if the constructor has the same names as the node
        for (label(lblName, ltype) <- args){
            if (!getKeywordParameters(n)[lblName]? || (!(\list(adt(_,[])):= ltype) && ltype != \value())){
                continue;
            }
        }
        //Construct the arguments for the constructor
        list[value] vals = [];
        for (label(name, lblType) <- args){
            //If empty, continue
            if (getKeywordParameters(n)[name] == ""){
                vals += nothing();
                continue;
            }
            //Check if column is optional
            if (name in optional[getName(n)]){
                //Check if column is a subblock
                if (\list(adt(adtName,[])):= lblType && list[node] children := getKeywordParameters(n)[name]){
                    vals += just([[node2data(n1, type(adt(adtName,[]),t.definitions),optional) | node n1 <- children]]);
                }
                //Check which type is filled in with
                else if (appl(prod(sort(a), _, _), _) := getKeywordParameters(n)[name]){
                    if (adt("Maybe", [sort(a)]) := lblType){
                        vals += just(getKeywordParameters(n)[name]);
                    }
                    else{
                        throw "Type mismatch for node <getName(n)>,<name> expected <adt("Maybe", [sort(a)])> but got <lblType>"; 
                    }
                }
            }
            // if column is not optional
            else {
                //Check if column is a subblock
                if (\list(adt(adtName,[])):= lblType && list[node] children := getKeywordParameters(n)[name]){
                    vals += [[node2data(n1, type(adt(adtName,[]),t.definitions),optional) | node n1 <- children]];
                }
                //Check which type is filled in with
                else if (appl(prod(sort(a), _, _), _) := getKeywordParameters(n)[name]){
                    if (sort(a) := lblType){
                        vals += getKeywordParameters(n)[name];
                    }
                    else{
                        throw "Type mismatch for node <getName(n)>,<name> expected <sort(a)> but got <lblType>"; 
                    }
                }
            }
        }
        //Make the instance
        return make(type(adt(getName(n),[]),t.definitions), consName, vals);
    }
    throw "No constructor found for node <n>";
}
