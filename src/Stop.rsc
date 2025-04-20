module Stop

import ParseTree;
import IO;  
import Node;
import Type;
data Forms     = forms(str name, list[Question] questions);
data Question  = question(str question, str maxlength, str name, str \value, str \type, str condition);
    
void main() {
    // node qlNode = 
    //     "Forms"(name="\"A\"",questions=["Question"(question="\"Whats the weather?\"",maxlength="100",name="Question 1",\value="",\type="string",condition="true"),"Question"(question="\"Whats the weather?\"",maxlength="100",name="Question 2",\value="",\type="string",condition="true")]);
    println(getName(#Forms));
}
