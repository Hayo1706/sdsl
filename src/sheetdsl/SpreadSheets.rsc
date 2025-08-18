module sheetdsl::SpreadSheets
import IO;
import List;

private list[str] alpha = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"];
private list[str] numeric = ["<i>" | int i <- [0..50]];
str intToColumnName(int i) = (i >= 26 ? intToColumnName(i/26): "") + alpha[i % 26]; 


// Create a default spreadsheet with standard width and height with ABCDE... column headers, 1234... row headers, and an empty data matrix.
SpreadsheetData spreadSheetData() 
    = spreadSheetData(size(numeric), alpha, rowHeaders=numeric);

// Create a default spreadsheet with a given number of rows and columns
SpreadsheetData spreadSheetData(int rows, int cols) 
    = spreadSheetData(rows, [intToColumnName(i) | int i <- [0..cols]]); 

// Create spreadsheet with a given number of rows and columns and own labels, potentially with custom row headers.
SpreadsheetData spreadSheetData(int rows, list[str] labels, list[str] rowHeaders = ["<i>" | int i <- [0..rows]]) 
    = spreadSheetData(labels, rowHeaders, [["" | int _ <- [0..size(labels)]] | int i <-[0..size(rowHeaders)]]); 


// Create spreadsheet data with the given labels, row headers, and data matrix. The data can be extended with empty rows if the number of rows is greater than the data matrix.
SpreadsheetData spreadSheetData(list[list[value]] \data, int rows=size(\data), list[str] labels=[intToColumnName(i) | int i <- [0..size(\data[0])]], list[str] rowHeaders = ["<i>" | int i <- [0..rows]]) {
    int defaultDataRows = size(\data);
    if (size(labels) != size(\data[0])) 
        throw ("The number of columns in the data does not match the number of labels");
    if (defaultDataRows > size(rowHeaders) || rows > size(rowHeaders))
        throw ("The number of rows given is greater than the number of rowHeaders");
    // Extend the data with empty rows
    for (int _ <- [defaultDataRows..rows]) {
        \data += [["" | int _ <- [0..size(labels)]]];
    }
    return spreadSheetData(labels, rowHeaders, \data);
}

// A spreadsheet is a data structure that contains the data, comments, row heights, column widths, and whether to enable column and row headers.
data SpreadSheet
    = spreadSheet(
        SpreadsheetData sheetData = spreadSheetData(),
        list[CommentData] comments = [],
        int rowHeights = 30,
        int colWidths = 120,
        bool enableColHeaders = true,
        bool enableRowHeaders = true
    );

// A spreadsheet data structure that contains the column headers, row headers, and the data matrix.
data SpreadsheetData
    = spreadSheetData(
        list[str] columnHeaders,
        list[str] rowHeaders,
        list[list[value]] \data
    );


// These are the types of errors that can occur in the spreadsheet comments.
data ErrorType 
 = error()
 | warning()
 | parseerror()
 | structuralerror();

// Convert a message to a CommentData object with the given class type.
CommentData commentData(int row, int col, str text, ErrorType class)
  = commentData(row, col, comment(text), class);

CommentData commentData(int row, int col, int text, ErrorType class)
  = commentData(row, col, comment(text), class);


// Replace the comment at the given row and column with a new comment.
public list[CommentData] replaceComment(list[CommentData] cs, int row, int col, value newText, ErrorType className) 
    = removeComment(cs, row, col) + commentData(row, col, newText, className);


// Remove the comment at the given row and column from the list of comments.
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
