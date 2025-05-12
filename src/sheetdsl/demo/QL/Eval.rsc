module sheetdsl::demo::QL::Eval

import sheetdsl::demo::QL::Definitions;
import sheetdsl::Syntax;

import String;
import ParseTree;
import IO;
import util::Math;
import util::Maybe;

/*
 * Big-step semantics for QL
 */
 
// NB: Eval assumes the form is type- and name-correct.

// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment, mapping question names to values.
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input = user(str question, Value \value);
  

Value type2default((Types)`integer`) = vint(0);
Value type2default((Types)`string`) = vstr("");
Value type2default((Types)`boolean`) = vbool(false);


// produce an environment which for each question has a default value
// using the function type2default function defined above.
// observe how visit traverses the form and match on normal questions and computed questions.

VEnv initialEnv(Forms f) {
  VEnv env = ();
  visit(f) {
    case Question q:
      env["<q.name>"] = type2default(q.types);
  }
  return eval(f,user("",vint(0)), env);
}

// Expression evaluation (complete for all expressions)
Value eval((Expr)`<Id x>`, VEnv venv) = venv["<x>"];


Value eval((Expr)`<Str x>`, VEnv venv) = vstr("<x>"[1..-1]);      // String literal

Value eval((Expr)`<Bool x>`, VEnv venv) = vbool("<x>" == "true");  // Boolean literal

Value eval((Expr)`<Int x>`, VEnv venv) = vint(toInt("<x>"));  // Integer literal


Value eval((Expr)`(<Expr e>)`, VEnv venv) = eval(e, venv);

// Exponentiation (right-associative)
Value eval((Expr)`<Expr left> ^ <Expr right>`, VEnv venv) = vint(toInt(pow(eval(left, venv).n, eval(right, venv).n)));

// Multiplication and Division (left-associative)
Value eval((Expr)`<Expr left> * <Expr right>`, VEnv venv) = vint(eval(left, venv).n * eval(right, venv).n);

Value eval((Expr)`<Expr left> / <Expr right>`, VEnv venv) = vint(eval(right, venv).n != 0 ? eval(left, venv).n / eval(right, venv).n : 0);

// Addition and Subtraction (left-associative)
Value eval((Expr)`<Expr left> + <Expr right>`, VEnv venv) = vint(eval(left, venv).n + eval(right, venv).n);

Value eval((Expr)`<Expr e1> - <Expr e2>`, VEnv venv) = vint(eval(e1, venv).n - eval(e2, venv).n);

// Comparison operations (>, <, <=, >=)
Value eval((Expr)`<Expr left> \> <Expr right>`, VEnv venv) = vbool(eval(left, venv).n > eval(right, venv).n);

Value eval((Expr)`<Expr left> \< <Expr right>`, VEnv venv) = vbool(eval(left, venv).n < eval(right, venv).n);

Value eval((Expr)`<Expr left> \<= <Expr right>`, VEnv venv) = vbool(eval(left, venv).n <= eval(right, venv).n);

Value eval((Expr)`<Expr left> \>= <Expr right>`, VEnv venv) = vbool(eval(left, venv).n >= eval(right, venv).n);

// Equality and inequality (==, !=)
Value eval((Expr)`<Expr left> == <Expr right>`, VEnv venv) = vbool(eval(left, venv).n == eval(right, venv).n);

Value eval((Expr)`<Expr left> != <Expr right>`, VEnv venv) = vbool(eval(left, venv).n != eval(right, venv).n);

// Logical NOT
Value eval((Expr)`! <Expr operand>`, VEnv venv) = vbool(!eval(operand, venv).b);

// Logical AND (&&)
Value eval((Expr)`<Expr left> && <Expr right>`, VEnv venv) = vbool(eval(left, venv).b && eval(right, venv).b);

// Logical OR (||)
Value eval((Expr)`<Expr left> || <Expr right>`, VEnv venv) = vbool(eval(left, venv).b || eval(right, venv).b);



// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(Forms f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

// evaluate the questionnaire in one round 
VEnv evalOnce(Forms f, Input inp, VEnv venv)
  = ( venv | eval(q, inp, it) | Question q <- f.questions );


VEnv eval(Question q, Input inp, VEnv venv) {
  // if the question's condition is not satisfied, skip it
  if (just(cond) := q.condition){
    Value condValue = eval(cond, venv);
    if (!(condValue is vbool && condValue == vbool(true))) {
      return venv;
    }
  }
  
  // Computed questions
  if (just(val) := q.\value){
    venv["<q.name>"] = eval(val, venv);
    return venv;
  }
  
  // Answerable questions
  if (inp.question == "<q.name>") {
    venv["<q.name>"] = inp.\value;
  }
  return venv;
}

/*
 * Rendering UIs: use questions as widgets
 */

list[Question] render(Forms form, VEnv venv) {
  list[Question] renderedQuestions = [];
  for (Question q <- form.questions) {
    renderedQuestions += renderQ(q, venv);
  }
  return renderedQuestions;
}

list[Question] renderQ(Question q, VEnv venv) {
  if (just(cond) := q.condition){
    Value condValue = eval(cond, venv);
    if (!(condValue is vbool && condValue == vbool(true))) {
      return [];
    }
  }
  // Computed questions
  if (just(val) := q.\value){
    return [question(q.name, q.question, q.types, just(value2expr(eval(val, venv))), q.condition)];
  }

  return [q];
}

Expr value2expr(vbool(bool b)) = [Expr]"<b>";
Expr value2expr(vstr(str s)) = [Expr]"\"<s>\"";
Expr value2expr(vint(int i)) = [Expr]"<i>";

