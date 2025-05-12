
module sheetdsl::ParserSDSL

import sheetdsl::Syntax;
import Node;
import IO;
import List;
import Set;
import Map;
import vis::Text;
import Message;
import util::Math;
import util::Maybe;
import ParseTree;
import Type;


alias Matrix = list[list[value]];

int length(l) = (0| it + 1 | item <- l);

loc CoordsToLoc(int row, int col){
    str coords = "<row>" + "," + "<col>";
    return |cell://<coords>|(0,0,<0,0>,<0,0>);
}

bool isEmptyRow(list[value] row, int colStart = 0, int colEnd = size(row)){
    for (int i <- [colStart..colEnd]) {
        if (row[i] != "") {
            return false;
        }
    }
    return true;
}

map[str, Block] getBlocks(start[SDSL] s){
    map[str, Block] blocks = ();
    visit(s){
        case Block b:{
            blocks["<b.name>"] = b;
        }
    }
    return blocks;

}


private int getNextBlockInstance(Matrix m, int rowStart, Block b, int colStart){
    for(int r <- [rowStart+1..size(m)]){
        int colIdx = colStart;
        for (Element column <- b.elems){
            if(column is col && column.assign is required){
                if (m[r][colStart] != "") return r;
            }
            colIdx += 1;
        }
    }
    return size(m);
}

Matrix removeEmptyRows(Matrix m) = [l | list[value] l <- m, !isEmptyRow(l)];

public set[Message] checkRequiredBlocks(Matrix m, start[SDSL] s) {
    Matrix filtered = removeEmptyRows(m);
    return checkRequiredBlock(m, s.top.topBlock.b, 0, size(m), 0, getBlocks(s))[0];
} 

private tuple[set[Message], bool] checkRequiredBlock(Matrix m, Block b, int startRow, int endRow, int colStart, map[str, Block] blocks){
    set[Message] messages = {};
    bool empty = true;
    int row = startRow;
    while (row < endRow){
        int colIdx = colStart;
        int nextRow = row + 1;
        if (isEmptyRow(m[row])){
            row += 1;
            continue;
        }
        for (Element column <- b.elems){
            if(column is col && column.assign is required){
                if (m[row][colIdx] == "") messages += error("Cell is required but empty", CoordsToLoc(row,colIdx));
                else empty = false;
                colIdx += 1;
            }
            else if(column is sub){
                if (column has multiple)
                    nextRow = min(endRow,getNextBlockInstance(m,row,b,colStart));

                tuple[set[Message], bool] newMessages = checkRequiredBlock(m, blocks["<column.subBlock.name>"], row, nextRow, colIdx, blocks);
                if (column.assign is required){
                    messages += newMessages[0];
                }
                else if (column.assign is optional){
                    if (!newMessages[1]){
                        messages += newMessages[0];
                    }
                }
                colIdx += length(blocks["<column.subBlock.name>"].elems);
            }
        }
        row = nextRow;
    }
    return <messages, empty>;
}




list[node] parseData(Matrix m, start[SDSL] s){
    Matrix filtered = removeEmptyRows(m);
    int amountRows = size(filtered);
    return scanBlock(filtered, s.top.topBlock.b, amountRows, getBlocks(s));
}

// This makes some ssumptions: first rows are not empty. No empty rows between data. Only one type of top block.
list[node] scanBlock(Matrix m, Block b, int amountRows, map[str, Block] blocks, int startRowIdx = 0, int startColIdx = 0){
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
                    m,blocks["<column.subBlock.name>"],nextBlock,blocks, startRowIdx=row,startColIdx=startColIdx + colIdx
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
    map[str, Block] blocks = getBlocks(s);
    for (key <- blocks){
        list[str] optional = [];
        for (Element e <- blocks[key].elems){
            if (e.assign is optional){
                optional += "<e.name>";
            }
        }
        optionalInstances[key] = optional;
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


public value node2data(list[node] n, type[&T] t, start[SDSL] s) = [node2data(n1, t, s) | node n1 <- n];

public value node2data(node n, type[&T] t, start[SDSL] s) = node2data(n, t, getOptionalInstances(s));

//Convert a node to a data type with the same names, types and values
public value node2data(node n, type[&T] t, map[str,list[str]] optional) {
    //Get all the constructors for the type
    choice(_,alts) = t.definitions[adt(getName(n),[])];
    //Loop over all the constructors
    for (c:cons(label(consName, _), args, _, _) <- alts){
        //Check if the constructor has the same amount of arguments as the node
        if (size(args) != size(getKeywordParameters(n))){
            continue;
        }
        //Check if the constructor has the same names as the node
        for (label(lblName, ltype) <- args){
            if (!getKeywordParameters(n)[lblName]?){
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
                else if (appl(prod(label(_,a), _, _), _) := getKeywordParameters(n)[name] || appl(prod(a, _, _), _) := getKeywordParameters(n)[name]){
                    if (adt("Maybe", [a]) := lblType){
                        vals += just(getKeywordParameters(n)[name]);
                    }
                    else{
                        throw "Type mismatch for node <getName(n)>,<name> expected <adt("Maybe", [a])> but got <lblType>"; 
                    }
                }
            }
            // if column is not optional
            else {
                testing = getKeywordParameters(n)[name];
                //Check if column is a subblock
                if (\list(adt(adtName,[])):= lblType && list[node] children := getKeywordParameters(n)[name]){
                    vals += [[node2data(n1, type(adt(adtName,[]),t.definitions),optional) | node n1 <- children]];
                }
                //Check which type is filled in with
                
                else if (appl(prod(label(_,a), _, _), _) := getKeywordParameters(n)[name] || appl(prod(a, _, _), _) := getKeywordParameters(n)[name]){
                    if (a := lblType){
                        vals += getKeywordParameters(n)[name];
                    }
                    else{
                        throw "Type mismatch for node <getName(n)>,<name> expected <a> but got <lblType>"; 
                    }
                }
            }
        }
        //Make the instance
        t = type(adt(getName(n),[]),t.definitions);
        return make(t, consName, vals);
    }
    throw "No constructor found for node <n>";
}
