module sheetdsl::demo::QL::Definitions
layout WS = [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000]* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000];

syntax Types   
  = boolean: "boolean"
  | integer: "integer"
  | string: "string";

syntax Bool = "true" | "false";
syntax Int = [\-]?[0-9]+; 

syntax Expr
  = bracket "(" Expr ")"
  | "!" Expr
  > Int | Bool | Str
  > var: Id name \ "true" \"false" \ "required" \ "range" \ "regex" \ "form" \ "if" \ "else"      
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


import util::Maybe;
import sheetdsl::Syntax;

data Forms     = forms(Str name, list[Question] questions);
data Question  = question(Id name, Str question, Types types, Maybe[Expr] \value, Maybe[Expr] condition);
