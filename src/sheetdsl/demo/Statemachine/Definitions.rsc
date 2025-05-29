module sheetdsl::demo::Statemachine::Definitions

import util::Maybe;
import sheetdsl::Syntax;
layout WS = [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000]* !>> [\u0009-\u000D \u0020 \u0085 \u00A0 \u1680 \u180E \u2000-\u200A \u2028 \u2029 \u202F \u205F \u3000];

syntax Int = [0-9]+;
syntax Bool = "true" | "false";

syntax Id = [A-Z 0-9 _] !<< [A-Z][A-Z 0-9 _]* !>> [A-Z 0-9 _];
syntax Check = "x" | "X";
syntax Kind = "analog" | "digital";

syntax Types   
  = boolean: "boolean"
  | integer: "integer"
  | string: "string";


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

data Sensor = sensor(
    Id id,
    Str description,
    Types \type,
    Kind kind
);

data State = state(
    Int stepnum,
    Str description,
    Maybe[list[Transition]] transitions
);

data Transition = transition(
    Int to,
    Str description,
    Expr condition
);

data Activations = activations(
    Int stepnum,
    Str description,
    Maybe[Check] motor1,
    Maybe[Check] motor2,
    Maybe[Check] heater1,
    Maybe[Check] valve1
);