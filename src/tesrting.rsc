module tesrting
import IO;
import String;
void main() {


    str before = "A";
    str error  = "B";
    str after  = "C";

    str input =
    "\<pre id=\"hltx\"\>"
    + before
    + "\<span " + (trim(error) == "" ? "style=\"background: red\"" : "") + " id=\"hltx\" class=\"errorText\"\>"
    + error
    + "\</span id=\"hltx\"\>"
    + after
    + "\</pre id=\"hltx\"\>";
    println( /\<\/?(pre\|span)\b[^\>]*\bid\s*=\s*<q:['"]>hltx<q>[^\>]*\>/i := "\<pre id=\"hltx\"\>x\</pre id=\"hltx\"\>"); // yields: false
    println(stripHLTX(input)); // yields: "ABC"
}

public str stripHLTX(str s){
    s = visit(s) {
        case /\<\/?(pre\|span)\b[^\>]*\bid\s*=\s*<q:['"]>hltx<q>[^\>]*\>/i => ""
    };
    return s;
}