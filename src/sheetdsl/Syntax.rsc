module sheetdsl::Syntax

extend lang::std::Layout;
extend lang::rascal::\syntax::Rascal;


start syntax SDSL = "top" Block topBlock Block* subBlocks SyntaxDefinition+ grammarDefs; 

syntax Str = [\"]![\"]* [\"];
syntax Id = [a-z A-Z 0-9 _] !<< [a-z A-Z][a-z A-Z 0-9 _]* !>> [a-z A-Z 0-9 _];
lexical Assign = required: "=" | optional:"?=";

syntax Block
  = "block" Id name "{" Element+ elems "}";

syntax Element
  = col: Id name               Assign assign Column column";"
  | sub: Id name [*]? multiple Assign assign SubBlock subBlock ";";

syntax Column = "column" Str header ":" Nonterminal ref;
syntax SubBlock = "block" Id name;

