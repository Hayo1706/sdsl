module sheetdsl::demo::Statemachine::Check

import Message;
import IO;
import ParseTree;
import List;
import String;
import util::Maybe;
extend sheetdsl::demo::Statemachine::Definitions;

syntax Types = "*unknown*";


alias TEnv = lrel[str, Types];
alias Steps = list[str];

TEnv collect(list[Sensor] f) {
  TEnv env = [];
  for (Sensor s <- f) {
    env = env + <"<s.id>", s.\type>;
  }
  return env;
}

Steps collect(list[State] f) {
  Steps steps = [];
  for (State s <- f) {
    steps += "<s.stepnum>";
  }
  return steps;
}

// the fall back type is *unknown*
default Types typeOf(Expr _, TEnv env) = (Types)`*unknown*`;

// a reference has the type of its declaration
Types typeOf((Expr)`<Id x>`, TEnv env) = t
    when <"<x>", Types t> <- env;

Types typeOf((Expr)`(<Expr e>)`, TEnv env) = typeOf(e, env);
Types typeOf((Expr)`<Int _>`, TEnv env) = (Types)`integer`;
Types typeOf((Expr)`<Bool _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Str _>`, TEnv env) = (Types)`string`;
Types typeOf((Expr)`<Expr _> \< <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> \> <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> \>= <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> \<= <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> == <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> != <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> || <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> && <Expr _>`, TEnv env) = (Types)`boolean`;
Types typeOf((Expr)`<Expr _> + <Expr _>`, TEnv env) = (Types)`integer`;
Types typeOf((Expr)`<Expr _> * <Expr _>`, TEnv env) = (Types)`integer`;
Types typeOf((Expr)`<Expr _> / <Expr _>`, TEnv env) = (Types)`integer`;
Types typeOf((Expr)`<Expr _> - <Expr _>`, TEnv env) = (Types)`integer`;


/*
 * Checking forms
 */


set[Message] check(list[State] states, list[Sensor] sensors) 
  = { *check(s, env, steps) | State s <- states }
        when TEnv env := collect(sensors), Steps steps := collect(states);

set[Message] check(list[Activations] activations, list[State] states) 
  = { *check(a, steps) | Activations a <- activations }
        when Steps steps := collect(states);


set[Message] check(s:state(_,_, nothing()), TEnv env, Steps steps) = {};

set[Message] check(s:state(_,_, just(transitions)), TEnv env, Steps steps) = 
    { *check(t, env, steps) | Transition t <- transitions };



set[Message] check(t:transition(to, _, e), TEnv env, Steps steps) = 
    { error("undefined step number: <to>", to.src) | "<to>" notin steps } +
    { error("condition must be boolean", e.src) | (Types)`boolean` !:= typeOf(e, env), (Types)`*unknown*` !:= typeOf(e, env) } +
    check(e, env);

set[Message] check(Activations a, Steps steps) = 
    { error("undefined step number: <a.stepnum>", a.stepnum.src) | "<a.stepnum>" notin steps };

/*
 * Checking expressions
 */


// when the other cases fail, there are no errors
default set[Message] check(Expr _, TEnv env) = {};

set[Message] check(e:(Expr)`<Id x>`, TEnv env) = {error("undefined variable: <x>", x.src)}
    when "<x>" notin env<0>;

set[Message] check((Expr)`(<Expr e>)`, TEnv env) = check(e, env);


// Helper function for logical operators
set[Message] validateLogicalOperands(Expr left, Expr right, TEnv env) {
    set[Message] messages = {};
    messages += { error("Invalid operand for logical operation", left.src) | (Types)`boolean` !:= typeOf(left, env), (Types)`*unknown*` !:= typeOf(left, env)};
    messages += { error("Invalid operand for logical operation", right.src) | (Types)`boolean` !:= typeOf(right, env) , (Types)`*unknown*` !:= typeOf(right, env) };
    messages += check(left, env);
    messages += check(right, env);
    return messages;
}

set[Message] check((Expr)`<Expr left> && <Expr right>`, TEnv env) = validateLogicalOperands(left, right, env);
set[Message] check((Expr)`<Expr left> || <Expr right>`, TEnv env) = validateLogicalOperands(left, right, env);


// Helper function for equality/inequality operators
set[Message] validateEqualityOperands(Expr expr, Expr left, Expr right, TEnv env) {
    return { error("Operands must have the same type for equality/inequality checks", expr.src)
    | Types leftType := typeOf(left, env), (Types)`*unknown*` !:= typeOf(left, env), leftType !:= typeOf(right, env), (Types)`*unknown*` !:= typeOf(right, env) } + check(left, env) + check(right, env);
}

set[Message] check((Expr)`<Expr left> == <Expr right>`, TEnv env) = validateEqualityOperands((Expr)`<Expr left> == <Expr right>`, left, right, env);
set[Message] check((Expr)`<Expr left> != <Expr right>`, TEnv env) = validateEqualityOperands((Expr)`<Expr left> != <Expr right>`, left, right, env);


// Helper function for comparison operations
set[Message] validateComparisonOperands(Expr left, Expr right, TEnv env) {
    set[Message] messages = {}; 
    messages += { error("Operands must be integers for comparison", left.src) | (Types)`integer` !:= typeOf(left, env) , (Types)`*unknown*` !:= typeOf(left, env) };
    messages += { error("Operands must be integers for comparison", right.src) | (Types)`integer` !:= typeOf(right, env) , (Types)`*unknown*` !:= typeOf(right, env) };
    messages += check(left, env);
    messages += check(right, env);
    return messages;
}

set[Message] check((Expr)`<Expr left> \< <Expr right>`, TEnv env) = validateComparisonOperands(left, right, env);
set[Message] check((Expr)`<Expr left> \<= <Expr right>`, TEnv env) = validateComparisonOperands(left, right, env);

set[Message] check((Expr)`<Expr left> \> <Expr right>`, TEnv env) = validateComparisonOperands(left, right, env);
set[Message] check((Expr)`<Expr left> \>= <Expr right>`, TEnv env) = validateComparisonOperands(left, right, env);

// Helper function to validate arithmetic expressions
set[Message] validateArithmeticOperands(Expr left, Expr right, TEnv env) {
    set[Message] messages = {}; 
    messages += { error("Invalid operand for arithmetic operation", left.src) | (Types)`integer` !:= typeOf(left, env) , (Types)`*unknown*` !:= typeOf(left, env)};
    messages += { error("Invalid operand for arithmetic operation", right.src) | (Types)`integer` !:= typeOf(right, env) , (Types)`*unknown*` !:= typeOf(right, env) };
    messages += check(left, env);
    messages += check(right, env);
    return messages;
}

set[Message] check((Expr)`<Expr left> + <Expr right>`, TEnv env) = validateArithmeticOperands(left, right, env);
set[Message] check((Expr)`<Expr left> - <Expr right>`, TEnv env) = validateArithmeticOperands(left, right, env);
set[Message] check((Expr)`<Expr left> * <Expr right>`, TEnv env) = validateArithmeticOperands(left, right, env);
set[Message] check((Expr)`<Expr left> / <Expr right>`, TEnv env) = validateArithmeticOperands(left, right, env);

 
