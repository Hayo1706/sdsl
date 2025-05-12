module sheetdsl::demo::QL::App

import salix::HTML;
import salix::App;
import salix::Core;
import salix::Index;

import sheetdsl::demo::QL::Definitions;
import sheetdsl::demo::QL::Eval;
import IO;
import sheetdsl::Syntax;
import util::Maybe;

import String;

// The salix application model is a tuple
// containing the questionnaire and its current run-time state (env).
alias Model = tuple[Forms form, VEnv env];

App[Model] runQL(Forms ql) = webApp(qlApp(ql), |project://sdsl/src/sheetdsl/demo/QL|);

SalixApp[Model] qlApp(Forms ql, str id="QL") 
  = makeApp(id, 
        Model() { return <ql, initialEnv(ql)>; }, 
        withIndex("<ql.name>"[1..-1], id, view, css=["https://cdn.simplecss.org/simple.min.css"]), 
        update);


// The salix Msg type defines the application events.
data Msg
  = updateInt(str name, str n)
  | updateBool(str name, bool b)
  | updateStr(str name, str s)
  ;

// We map messages to Input values 
// to be able to reuse the interpreter defined in Eval.
Input msg2input(updateInt(str q, str n)) = user(q, vint(toInt(n)));
Input msg2input(updateBool(str q, bool b)) = user(q, vbool(b));
Input msg2input(updateStr(str q, str s)) = user(q, vstr(s));

// The Salix model update function simply evaluates the user input
// to obtain the new state. 
Model update(Msg msg, Model model) = model[env=eval(model.form, msg2input(msg), model.env)];

// Salix view rendering works by "drawing" on an implicit HTML canvas.
// Look at the Salix demo folder to learn how html elements are drawn, and how element nesting is achieved with
// nesting of void-closures.
void view(Model model) {
    h3("<model.form.name>"[1..-1]);
    ul(() {
        // Render each enabled question
        list[Question] enabledQuestions = render(model.form, model.env);
        for (Question q <- enabledQuestions) {
            li(() { viewQuestion(q, model); });
        }
    });
}
Msg(str) updateInt(str name) = Msg(str n) { return updateInt(name, n);};

// fill in: question rendering, but only if they are enabled.
void viewQuestion(question(name, question, types, nothing(), _), Model model) {
    // Render input fields for answerable questions
    label("<question>"[1..-1]);
    switch (types) {
        case (Types)`boolean`:{
            input(
                \type("checkbox"),
                \checked(model.env["<name>"] == vbool(true)),
                \onClick(updateBool("<name>", !model.env["<name>"].b))
            );
            
        }
        case (Types)`integer`:
            input(
                \type("number"),
                \value("<model.env["<name>"].n>"),
                \onChange(updateInt("<name>"))
            );
        case (Types)`string`:
            input(
                \type("text"),
                \value("<model.env["<name>"].s>")
            );
        }
}

void viewQuestion(question(name, question, types, just(expr), _), Model model) {
    // Render read-only fields for computed questions
    label("<question>"[1..-1]);
    str val = "";
    switch (types) {
        case (Types)`boolean`:
            val = "<eval(expr, model.env).b>";
        case (Types)`integer`:
            val = "<eval(expr, model.env).n>";
        case (Types)`string`:
            val = "<eval(expr, model.env).s>";
        }
    span(val);
}