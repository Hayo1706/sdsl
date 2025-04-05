module Stop

import ParseTree;
import Exception;
import IO;
import Syntax;
import Set;
import lang::rascal::\syntax::Rascal;
import lang::rascal::format::Grammar;
import lang::rascal::grammar::definition::Productions;
import lang::rascal::grammar::definition::Layout;
import lang::rascal::grammar::definition::Symbols;
import IO;  
// import util::Maybe;
import Grammar;
import salix::util::Highlight;
void main() {
    // Grammar g = grammar(#start[Expr]);
    // g = \layouts(g, \layouts("Whitespace"), {});
    // parse(#start[Expr], "10+ 10");
    // parse(type(sort("Expr"), g.rules),"10+10");
    // println(g);
    SyntaxDefinition lay = (SyntaxDefinition)`layout WS = [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000]* !\>\> [\\u0009-\\u000D \\u0020 \\u0085 \\u00A0 \\u1680 \\u180E \\u2000-\\u200A \\u2028 \\u2029 \\u202F \\u205F \\u3000];`;
    start[SDSL] p = parse(#start[SDSL], |project://sdsl-1/src/test.sdsl|);
    set[SyntaxDefinition] defs = lay + {syn | SyntaxDefinition syn <- p.top.grammarDefs};
    gr = \layouts(syntax2grammar(defs), \layouts("WS"), {});
    hallo = parse(type(sort("Expr"), gr.rules),"10 + 10");
    println(hallo);
    //highlightToHtml(hallo);
    // println(gr.starts);
    // println(gr.rules);
    // parse(type(sort("Expr"), gr.rules), "1 + 1");

    //println(grammar2rascal(#start[B]));
    //println("<rule2prod(p.top.grammarDefs[1])[0]>");
   // println("<(rule[0].def: choice(rule[0].def, rule | SyntaxDefinition syn <- p.top.grammarDefs))>")
    // map[Symbol, Production] lang = ();
    // for(SyntaxDefinition syn <- p.top.grammarDefs){
    //     set[Production] prod = rule2prod(syn)[0];
    //     Symbol s = getSingleFrom(prod).def;
    //     lang[s] = choice(s, prod);
    // }
    // try{ 
    //     val = parse(type(sort("Expr"), lang), "1+1"); 
    //     println(val);
    //     println("true");
    // }
    // catch ParseError(loc location):{
    //     println("false");
    // }
    
//     // ManualGrammar();
//     // println(grammar2rascal(parsingWithAManualGrammar()));

//     // parse(type(sort("MySort"), (sort("MySort") : choice(sort("MySort"), {prod(sort("MySort"), [lit("hello")],{})}))), "hello");
}
// public Grammar syntax2grammar(set[SyntaxDefinition] defs) {
//   set[Production] prods = {};
//   set[Symbol] starts = {};
//   println("TEST");
  
//   for (sd <- defs) {
//     <ps,st> = rule2prod(sd);
//     prods += ps;
//     if (st is just)
//       starts += st.val;
//   }
  
//   return grammar(starts, prods);
// }

// void ManualGrammar() {
//     visit(type(sort("MySort"), (sort("MySort") : choice(sort("MySort"), {prod(sort("MySort"), [lit("hello")],{})})))){
//         case type[Tree] gr : {
//             parsers(gr)(sort("MySort"), "hello");
//         }
//     }
    
// }

// Grammar parsingWithAManualGrammar() 
//   = grammar({sort("MySort")}, (sort("MySort") : prod(sort("MySort"), [lit("hello")],{}),
//   sort("MySort2") : prod(sort("MySort2"), [lit("hello")],{})));