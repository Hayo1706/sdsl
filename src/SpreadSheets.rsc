module SpreadSheets
import IO;
import List;

private list[str] alpha = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
private list[str] numeric = ["<i>" | int i <- [0..50]];
str intToColumnName(int i) = (i >= 26 ? intToColumnName(i/26): "") + alpha[i % 26]; 


SpreadsheetData spreadSheetData() 
    = spreadSheetData(alpha, numeric,[["" | int _ <- [0..size(alpha)]] | int i <-[0..size(numeric)] ]);

SpreadsheetData spreadSheetData(int rows, int cols) 
    = spreadSheetData([intToColumnName(i) | int i <- [0..cols]], ["<i>" | int i <- [0..rows]], [["" | int i2 <- [0..cols]] | int i <-[0..rows]]); 

SpreadsheetData spreadSheetData(int rows, list[str] labels) 
    = spreadSheetData(labels, ["<i>" | int i <- [0..rows]], [["" | int _ <- [0..size(labels)]] | int i <-[0..rows]]); 


data SpreadSheet
    = spreadSheet(
        SpreadsheetData sheetData = spreadSheetData(),
        list[CommentData] comments = []
    );

data SpreadsheetData
    = spreadSheetData(
        list[str] columnHeaders,
        list[str] rowHeaders,
        list[list[value]] \data
    );


CommentData commentData(int row, int col, str text)
  = commentData(row, col, comment(text));

CommentData commentData(int row, int col, int text)
  = commentData(row, col, comment(text));

public list[CommentData] replaceComment(list[CommentData] cs, int row, int col, value newText) 
    = removeComment(cs, row, col) + commentData(row, col, newText);


public list[CommentData] removeComment(list[CommentData] cs, int row, int col){
    for(int i <- [0..size(cs)]){
        if (cs[i].row == row && cs[i].col == col){
            return delete(cs, i);
        }
    }
    return cs;
}
    // = visit(cs){case [*prefix,commentData(row,col,_),*postfix] => [*prefix,*postfix]} + commentData(row,col,newText);

data CommentData 
    = commentData(
        int row,
        int col,
        Comment comment
    );

data Comment
    = comment(
        value \value
    );
