module Syntax

extend lang::std::Layout;
extend lang::std::Id;
//extend lang::rascal::\syntax::Rascal;

start syntax SDSL = Block* questions; 

lexical Str = [\"]![\"]* [\"];

lexical Bool = "true" | "false";

lexical Int = [\-]?[0-9]+; 

lexical Regex = "[\\" ![\n]+ "\\]";
// boolean, integer, string
syntax Type   
  = boolean: "boolean"
  | integer: "integer"
  | string: "string"
  | bexpr: "bexpr"
  | aexpr: "aexpr";

syntax Block
  = "block" Id name "{" Element* blocks "}";

syntax Element
  = Id name [*]? ("="|"?=") (Column | SubBlock) ";";

syntax Column = "column" Str name ":" Type* types;

syntax SubBlock = "block" Id name;

syntax Expr
  = bracket "(" Expr ")"
  | "!" Expr
  > Int | Bool | Str 
  > var: Id name \ "true" \"false" \ "required" \ "range" 
  \ "regex" \ "form" \ "if" \ "else" \ "block" \ "column" 
  \ "string" \ "integer" \ "boolean" \ "bexpr" \ "aexpr"
  > right Expr "^" Expr
  > left ( Expr "*" Expr  
          | Expr "/" Expr
          )
  > left ( Expr "+" Expr
          | Expr "-" Expr 
          )
  > left ( Expr "\>" Expr
          | Expr "\<" Expr
          | Expr "\<=" Expr
          | Expr "\>=" Expr
          | Expr "==" Expr
          | Expr "!=" Expr
          )
  > left Expr "&&" Expr
  > left Expr "||" Expr
  ;

