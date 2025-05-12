module sheetdsl::util::Error

import sheetdsl::SpreadSheets;
import String;
import Message;
import Exception;

public str highlightErrorSubstring(str code, int \start, int end) {
    str before = substring(code, 0, \start);
    str error  = \start == end ? " " : substring(code, \start, end);
    str after  = substring(code, end);

    return "\<pre id=\"hltx\"\>" 
          + before 
          + "\<span <trim(error) == "" ? "style=\"background: red\"" : ""> id=\"hltx\" class=\"errorText\"\>" 
          + error 
          + "\</span id=\"hltx\"\>" 
          + after
          + "\</pre id=\"hltx\"\>";
}

data CellLoc  = CellLoc(int row, int col);
CellLoc locOf(Message msg) {
    if(/<row:[0-9]+>,<col:[0-9]+>/ := msg.at.authority)
        return CellLoc(toInt(row), toInt(col));
    throw "Error: <msg> has no location, all errors should have a location set";
}

public tuple[CommentData, int, int] messageToCommentData(Message msg, bool isParseError) {
    CellLoc location = locOf(msg);
    return <commentData(location.row, location.col, comment("<msg.msg>"), isParseError ? parseerror() : msg is warning ? warning() : error()), 
            location.row, 
            location.col>;
}
