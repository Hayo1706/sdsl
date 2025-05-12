module sheetdsl::demo::QL::Check

import Message;
import IO;
import ParseTree;
import List;
import String;
extend sheetdsl::demo::QL::Definitions;
import sheetdsl::Syntax;
import util::Maybe;

// internal type to represent unknown 
syntax Types = "*unknown*";

// type environment maps question names to types
// (NB: it's not a map, because the form can contain errors!)
alias TEnv = lrel[str, Types];

// build a Type Environment (TEnv) for a questionnaire.
TEnv collect(Forms f) {
  TEnv env = [];
  visit(f) {
    case Question q:
        env = env + <"<q.name>", q.types>;
  }
  return env;
}

/*
 * typeOf: compute the type of expressions
 */

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


set[Message] check(Forms form) 
  = { *check(q, env) | Question q <- form.questions }
  + checkDuplicates(form)
  + checkCycles(form)
  when TEnv env := collect(form);

set[Message] checkCycles(Forms form) {
    set[Message] messages = {};
    rel[str, str, loc] dependencies = {};

    // Add dependencies for each question
    for (Question q <- form.questions) {
        if (question(name,_,_,just(cond),_) := q){
            visit(cond){
                case (Id) `<Id x>`:{
                    dependencies += <"<name>", "<x>", q.\value.val.src>;
                }
            }
        }
        if (question(name,_,_,_,just(cond)) := q){
            visit(cond){
                case (Id) `<Id x>`:{
                    dependencies += <"<name>", "<x>", q.condition.val.src>;
                }
            }
        }
    }
    

    for (<str x, x> <- dependencies<0,1>+) { // Iterate over transitive dependencies
        for (<_, x, loc a> <- dependencies) { // Match where the dependency ends with the same `x`
            messages += {error("cyclic dependency", a)};
        }
    }
    
    return messages;
}

set[Message] checkDuplicates(Forms form) {
    set[Message] messages = {};
    list[Question] defined = []; // Tracks the list of questions defined so far.
    for (Question q <- form.questions) {
        for (Question q2 <- defined){
            if ("<q2.name>" == "<q.name>"){
                if ("<q2.types>" != "<q.types>")
                        messages += error("Redeclared question name with different type: <q.name>", q.name.src);                        
                else if ("<q2.question>" != "<q.question>")
                        messages += warning("Redeclared question name: <q.name>", q.name.src);
                else if ("<q2.question>" == "<q.question>"){
                    messages += warning("Redeclared question name and text: <q.name>", q.name.src);
                }
            }
            else if ("<q2.question>" == "<q.question>"){
                messages += warning("Redeclared question text: <q.question>", q.question.src);
            }
        }
        defined += q;
        if ("<q.question>" == "<(Str)`""`>"){
            messages += warning("Empty question text", q.question.src);
        }
        
    }
    return messages;
}

/*
 * Checking questions
 */

// by default, there are no errors or warnings
default set[Message] check(Question _, TEnv _) = {};

set[Message] check(question(_,_,t, just(e), nothing()), TEnv env)
    = { error("incompatible types", e.src) | t !:= typeOf(e, env), (Types)`*unknown*` !:= typeOf(e, env) } 
    + check(e, env);

set[Message] ifcondition(Expr cond, Question then, TEnv env) {
    set[Message] messages = {};
    messages += { error("condition must be boolean", cond.src) | (Types)`boolean` !:= typeOf(cond, env), (Types)`*unknown*` !:= typeOf(cond, env)};
    messages += { warning("question is unreachable", then.name.src) | (Expr)`false` := cond};
    messages += { warning("if is always true", cond.src) | (Expr)`true` := cond};
    messages += {warning("question is empty", then.question.src) | (Str)`""` := then.question};
    messages += check(cond, env);
    return messages;
}

set[Message] check(q:question(_,_,_, nocamthing(), just(cond)), TEnv env)
    = ifcondition(cond, q, env);

set[Message] check(q:question(_,_,t, just(e), just(cond)), TEnv env)
    = ifcondition(cond, q, env)
    + { error("incompatible types", e.src) | t !:= typeOf(e, env) && (Types)`*unknown*` !:= typeOf(e, env)}
    + check(e, env);

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


void printTEnv(TEnv tenv) {
    for (<str x, Types t> <- tenv) {
        println("<x>: <t>");
    }
}
 
