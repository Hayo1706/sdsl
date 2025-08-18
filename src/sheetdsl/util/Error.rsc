module sheetdsl::util::Error

import sheetdsl::SpreadSheets;
import String;
import Message;
import Exception;

// This module provides utilities for handling errors in the context of a spreadsheet application.

// Highlight a substring in the text, using HTML formatting.
public str highlightErrorSubstring(str code, int \start, int end) {
    str before = substring(code, 0, \start);
    str error  = \start == end ? " " : substring(code, \start, end);
    str after  = substring(code, end);

    return "\<pre id=\"hltx\"\>" 
          + before 
          + "\<span id=\"hltx\" class=\"errorText <trim(error) == "" ? "emptycell" : "">\"\>" 
          + error 
          + "\</span id=\"hltx\"\>" 
          + after
          + "\</pre id=\"hltx\"\>";
}

// Convert a row and column index to a loc object representing a cell location, this can be read out later from the error message.
// The begin and end parameters are used to specify the start and end of the error range, which can be useful for highlighting specific parts of the cell content.
loc CoordsToLoc(int row, int col, int begin=0, int end=0) {
    str coords = "<row>" + "," + "<col>";
    return |cell://<coords>|(0,0,<0,begin>,<0,end>);
}
// Convert a loc object to a string representation of the cell location.
data CellLoc  = CellLoc(int row, int col);
CellLoc locOf(Message msg) {
    if(/<row:[0-9]+>,<col:[0-9]+>/ := msg.at.authority)
        return CellLoc(toInt(row), toInt(col));
    throw "Error: <msg> has no location, all errors need to have a location set";
}

// Convert a message type error() or warning() to a CommentData object with the given error type, which can be displayed in the spreadsheet.
public CommentData messageToCommentData(Message msg, ErrorType errorType) {
    CellLoc location = locOf(msg);
    return commentData(location.row, location.col, comment("<msg.msg>"), errorType);
}
