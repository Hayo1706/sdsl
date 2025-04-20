module Parser

import Syntax;
import Node;
import IO;
import List;
import Map;
alias Matrix = list[list[value]];


list[str] colNames = [];
map[str, Block] blocks = ();
list[Block] topLvlBlocks = [];

public list[node] parseSheet(Matrix m, start[SDSL] s){
    colNames = getColumnNames(s);
    blocks = getBlocks(s);
    topLvlBlocks = getTopBlocks(s);

    if (size(topLvlBlocks) > 1)
        throw "Only one top-level-block supported for now";
    return scanBlock(m, topLvlBlocks[0], size(m));
}

// This makes some ssumptions: first rows are not empty. No empty rows between data. Only one top block.
private list[node] scanBlock(Matrix m, Block b,int amountRows, int startRowIdx = 0, int startColIdx = 0){
    list[node] instances = [];
    int row = startRowIdx;
    while(row < amountRows){
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

        for(Element column <- b.elems){
            if (column is col)
                vals["<column.name>"] = m[row][startColIdx + colIdx];
            else if (column is sub){
                int nextBlock = calculateNextInstanceBlock(m,b,row,startColIdx);
                println("Next block:<nextBlock>");
                vals["<column.name>"] = scanBlock(
                    m,blocks["<column.subBlock.name>"],nextBlock, startRowIdx=row,startColIdx=startColIdx + colIdx
                );
                row = (nextBlock - 1); // Skip the rows until the next instance of this block;
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

bool reqColsFilled(Matrix m, Block b,int row,int colIdx){
    bool empty = true;
    for(Element column <- b.elems){
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

private list[str] getColumnNames(start[SDSL] s){
    list[str] names = [];
    visit(s){
        case Column c:{
            names += "<c.name>"[1..-1];
        }
    }
    return names;
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
public str prettyPrintIndented(value v) {
  str spaces = "  ";
  switch(v){
    case node n: {
      str name = getName(n);
      list[value] children = getChildren(n);
      map[str,value] kwParams = getKeywordParameters(n);

      // start with "Name"(
      str result = "<spaces>\"<name>\"(";
      bool first = true;

      // 1) positional children
      for (value child <- children) {
        if (!first) {
          result += ",";
        }
        result += "\n" + prettyPrintIndented(child);
        first = false;
      }

      // 2) keyword parameters
      for (str key <- kwParams) {
        if (!first) {
          result += ",";
        }
        result += "\n" + spaces + "  <key>="
              + prettyPrintIndented(kwParams[key]);
        first = false;
      }

      if (!first) {
        // we printed some child or kw field, so close on new line
        result += "\n<spaces>)";
      } else {
        // no children or fields, close right after "("
        result += ")";
      }
      return result;
    }
    case list[value] vals: {
      if (vals == []) {
        return "[]"; // empty list
      }
      str result = "<spaces>[";
      bool first = true;
      for (value elem <- vals) {
        if (!first) {
          result += ",";
        }
        result += "\n" + prettyPrintIndented(elem);
        first = false;
      }
      return result + "\n<spaces>]";
    }
    default:  return "<spaces><v>";
  }
}


