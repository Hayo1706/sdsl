module sheetdsl::SpreadSheets
import IO;
import List;

private list[str] alpha = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
private list[str] numeric = ["<i>" | int i <- [0..50]];
str intToColumnName(int i) = (i >= 26 ? intToColumnName(i/26): "") + alpha[i % 26]; 


SpreadsheetData spreadSheetData() 
    = spreadSheetData(alpha, numeric,[["" | int _ <- [0..size(alpha)]] | int i <-[0..size(numeric)]]);

SpreadsheetData spreadSheetData(int rows, int cols) 
    = spreadSheetData([intToColumnName(i) | int i <- [0..cols]], ["<i>" | int i <- [0..rows]], [["" | int i2 <- [0..cols]] | int i <-[0..rows]]); 

SpreadsheetData spreadSheetData(int rows, list[str] labels, list[str] rowHeaders = ["<i>" | int i <- [0..rows]]) 
    = spreadSheetData(labels, rowHeaders, [["" | int _ <- [0..size(labels)]] | int i <-[0..size(rowHeaders)]]); 

SpreadsheetData spreadSheetData(list[list[value]] \data, int rows=size(\data), list[str] labels=[intToColumnName(i) | int i <- [0..size(\data[0])]], list[str] rowHeaders = ["<i>" | int i <- [0..rows]]) {
    int dataRows = size(\data);
    if (size(labels) != size(\data[0])) 
        throw ("The number of columns in the data does not match the number of labels");
    if (dataRows > size(rowHeaders))
        throw ("The number of rows given is greater than the number of rows in the data");
    // Extend the data with empty rows
    for (int _ <- [dataRows..rows]) {
        \data += [["" | int _ <- [0..size(labels)]]];
    }
    return spreadSheetData(labels, rowHeaders, \data);
}

SpreadsheetData spreadSheetData(int rows, list[str] labels, list[list[value]] \data)
    = spreadSheetData(labels, ["<i>" | int i <- [0..rows]], \data);


data SpreadSheet
    = spreadSheet(
        SpreadsheetData sheetData = spreadSheetData(),
        list[CommentData] comments = [],
        int rowHeights = 30,
        int colWidths = 120,
        bool enableColHeaders = true,
        bool enableRowHeaders = true
    );

data SpreadsheetData
    = spreadSheetData(
        list[str] columnHeaders,
        list[str] rowHeaders,
        list[list[value]] \data
    );


data ErrorType 
 = error()
 | warning()
 | parseerror();

CommentData commentData(int row, int col, str text, ErrorType class)
  = commentData(row, col, comment(text), class);

CommentData commentData(int row, int col, int text, ErrorType class)
  = commentData(row, col, comment(text), class);

public list[CommentData] replaceComment(list[CommentData] cs, int row, int col, value newText, ErrorType className) 
    = removeComment(cs, row, col) + commentData(row, col, newText, className);


public list[CommentData] removeComment(list[CommentData] cs, int row, int col){
    for(int i <- [0..size(cs)]){
        if (cs[i].row == row && cs[i].col == col){
            return delete(cs, i);
        }
    }
    return cs;
}

data CommentData 
    = commentData(
        int row,
        int col,
        Comment comment,
        ErrorType className
    );

data Comment
    = comment(
        value \value
    );
