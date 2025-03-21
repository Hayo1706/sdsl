document.addEventListener("DOMContentLoaded", function() {
  // Now let's say we have an element we want to attach a custom event to:
  // We'll just create it right in the DOM:
  var dragDiv = document.createElement("div");
  dragDiv.textContent = "Drag me around";
  dragDiv.setAttribute("draggable", "true");
  document.body.appendChild(dragDiv);

  // Then we attach a plain JavaScript event listener:
  dragDiv.addEventListener("dragstart", function(e) {
    console.log("dragstart from custom JS event");
    
    // When you want to signal back to Rascal, do something like:
    //  1) Create the data object describing the event
    var data = {
      // type is mandatory so the Rascal side sees something like "integer"/"string"/whatever
      type: "string",  
      // or maybe "json" if you want to pass multiple fields
      value: "dragStart event!"  
    };

    //  2) Make a Salix message out of it. The first arg is the "handle" object,
    //     typically { id: "someId", maps: [...] }, but if you just want a bare-bones
    //     handle with an ID, that’s enough to identify it on the Rascal side.
    var msg = $salix.makeMessage({ 
      id: "dragStartedHandle"   // choose a unique ID you handle in Rascal
    }, data);

    //  3) Then push that message into Salix:
    $salix.handle({ message: msg });
  });
});
