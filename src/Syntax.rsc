module Syntax

extend lang::std::Layout;
extend lang::std::Id;
extend lang::rascal::\syntax::Rascal;


start syntax SDSL = Block+ questions SyntaxDefinition+ grammarDefs; 

lexical Str = [\"]![\"]* [\"];

syntax Block
  = "block" Id name "{" Element* blocks "}";

syntax Element
  = Id name [*]? ("="|"?=") (Column | SubBlock) ";";

syntax Column = "column" Str name ":" Nonterminal ref;

syntax SubBlock = "block" Id name;

