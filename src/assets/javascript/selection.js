const selectionState = {
    anchorCell: null, 
    extendCell: null, 
    selectedCells: new Set(),
    dragging: false,

    CellInFocus: null,
    CellInEdit: null,
};

let editor = null;
let table = null;

document.addEventListener("DOMContentLoaded", function() {
    table = document.getElementById("myTable");
    editor = document.getElementById('editor');

    table.addEventListener("mousedown", (event) => {
        if(selectionState.CellInFocus)
            selectionState.CellInFocus.blur();
        const cell = event.target.closest("td");
        if (!cell) return;
        cell.focus();
        selectionState.CellInFocus = cell;
        
        //start of drag code
        clearSelection();
        event.preventDefault(); // this prevents text selection on drag
        selectionState.dragging = true;
        selectionState.anchorCell = getIdxFromElem(cell);
        selectionState.selectedCells.add(cell);
    });

    table.addEventListener("mouseover", (e) => {
        if (!selectionState.dragging) return;
        const cell = e.target.closest("td");
        if (!cell) return;
        var newPos = getIdxFromElem(cell);

        // Only start dragging once mouse moves in different cell than start
        if (coordinatesSame(cell, selectionState.anchorCell)) return;
        selectionState.extendCell = newPos;
        drawSelection();
    });

    document.addEventListener("mouseup", () => {
        selectionState.dragging = false;
    });

    table.addEventListener("dblclick", (event) => {
        const cell = event.target.closest("td");
        if (!cell) return;

        setCellEditMode(cell);        
    });

    editor.addEventListener("blur", function() {finalizeCellEdit();});
    editor.addEventListener("click", function(e) {e.stopPropagation();});
    editor.addEventListener("keydown", function(e) {
        if (e.key === "Enter")
           finalizeCellEdit();
      });

    document.addEventListener("keydown", function (e) {
        // Start typing immediately in cell when focused and typing
        if (selectionState.CellInEdit)
            return;
        if ((selectionState.CellInFocus) && !selectionState.dragging ) {
            const isPrintable = e.key.length === 1;
            if (isPrintable && !e.ctrlKey){
                setCellEditMode(selectionState.CellInFocus);
                editor.value = editor.value + e.key;
                e.preventDefault(); // Prevent default page behavior
            }
        }
        if (selectionState.selectedCells.size === 0) return;

        // Delete
        if (e.key === "Delete" || e.key === "Backspace") {
            let changes = []
            var minMax = calculateIdxsMinMax(selectionState.anchorCell,selectionState.extendCell);
            for (let r = minMax.minRow; r <= minMax.maxRow; r++) {
                for (let c = minMax.minCol; c <= minMax.maxCol; c++) {
                    changes.push({row:r,col:c,change:""});
                }
            }   
            console.log(changes);
            sendBulkValues(changes);
            e.preventDefault();
        }

        // Copy
        if (e.ctrlKey && e.key === "c") {
            e.preventDefault();
            const copyText = buildClipboardText();
            navigator.clipboard.writeText(copyText);
        }

        // Paste
        if (e.ctrlKey && e.key === "v") {
            navigator.clipboard.readText().then((clipText) => {
                pasteClipboardText(clipText);
            });
        }
    });
});

function calculateIdxsMinMax(idx1, idx2){
    return {"minRow": Math.min(idx1.row, idx2.row), "minCol":Math.min(idx1.col, idx2.col), "maxRow":Math.max(idx1.row,idx2.row),"maxCol":Math.max(idx1.col,idx2.col)};
}

function idxBetweenRange(minMax, idx3){
    return idx3.row >= minMax.minRow && idx3.row <= minMax.maxRow && idx3.col >= minMax.minCol && idx3.col <= minMax.maxCol;
}

function coordinatesSame(idx1, idx2){
    return idx1.row === idx2.row && idx1.col === idx2.col;
}

function getIdxFromElem(elem){
    if (elem.nodeName === "TD")
        return {"row":elem.parentElement.getAttribute("aria-rowindex"),"col": elem.getAttribute("aria-colindex")};
    else if (elem.nodeName === "TR")
        return {"row":elem.getAttribute("aria-rowindex")};
}

function clearSelection() {
    selectionState.anchorCell = null;
    selectionState.extendCell = null;
    selectionState.selectedCells.forEach((cell) => {
        cell.classList.remove("selection");
    });
    selectionState.selectedCells.clear();
}

function drawSelection() {
    var minMax = calculateIdxsMinMax(selectionState.anchorCell,selectionState.extendCell);
    for (let r = minMax.minRow; r <= minMax.maxRow; r++) {
        const row = table.rows[r + 1];
        if (!row) continue;
        for (let c = minMax.minCol; c <= minMax.maxCol; c++) {
            const cell = row.cells[c + 1];
            if (cell) {
                selectionState.selectedCells.add(cell);
                cell.classList.add("selection");
            }
        }
    }

    // Remove class from cells no longer in selection
    for (const cell of selectionState.selectedCells) {
        if (!cell) continue;
        if (!idxBetweenRange(minMax,getIdxFromElem(cell))) {
            cell.classList.remove("selection");
            selectionState.selectedCells.delete(cell);
        }
    }
}


function setCellEditMode(cell){      
    selectionState.CellInEdit = cell;
    drawInput(cell);
    editor.value = cell.innerText;
    editor.focus();
}

function drawInput(cell){
    const cellRect = cell.getBoundingClientRect();
    editor.style.display = 'block';
    editor.style.top = `${cellRect.top + window.scrollY}px`;
    editor.style.left = `${cellRect.left + window.scrollX}px`;
    editor.style.width = (cellRect.width)+ 'px';
    editor.style.height = (cellRect.height)+ 'px';
    editor.style.border = "2px solid #37bc6c";
}
  
function finalizeCellEdit() {
    if (!selectionState.CellInEdit)
        return;
    sendNewValue(editor.value, selectionState.CellInEdit);
    hideEditor();
    editor.blur();

}

function hideEditor(){
    editor.style.display  = "none";
    selectionState.CellInEdit = null;
}

function buildClipboardText() {
    if (!selectionState.anchorCell || !selectionState.extendCell){
        if (selectionState.CellInFocus)
            return selectionState.CellInFocus.innerText.trimEnd();
        return "";
    }
    console.log(selectionState.anchorCell, selectionState.extendCell);
    var minMax = calculateIdxsMinMax(selectionState.anchorCell, selectionState.extendCell);
    let text = "";
    for (let r = minMax.minRow; r <= minMax.maxRow; r++) {
        let rowVals = [];
        for (let c = minMax.minCol; c <= minMax.maxCol; c++) {
            rowVals.push(table.rows[r + 1]?.cells[c + 1].innerText ?? "");
        }
        text += rowVals.join("\t") + "\n";
    }
    return text.trimEnd();
}

function pasteClipboardText(text) {
    if (!selectionState.CellInFocus || selectionState.CellInEdit)
        return
    const lines = text.split("\n").map(line => line.split("\t"));

    const anchoridx = getIdxFromElem(selectionState.CellInFocus);

    const changes = [];
    for (let r = 0; r < lines.length; r++) {
        for (let c = 0; c < lines[r].length; c++) {
            changes.push({
                row: parseInt(anchoridx.row) + r,
                col: parseInt(anchoridx.col) + c,
                change: lines[r][c]
            });
        }
    }
    sendBulkValues(changes);
}

function sendNewValue(newval, elem){
    if (newval === elem.innerText)
        return;
    if (selectionState.CellInEdit === elem){
        editor.value = newval;
        hideEditor();
    }
    var idx = getIdxFromElem(elem);
    console.log({value1: idx.row + "," + idx.col, value2:newval});
    
    $salix.send({"name":"targetValues","handle":{"id":2,"maps":[]}}, {value1: idx.row + "," + idx.col, value2:newval});
}

//format [{idx: "row,col", change: content}]
function sendBulkValues(changes){
    hideEditor();
    console.log(changes);
    $salix.send({"name":"jsonPayload","handle":{"id":4,"maps":[]}}, changes);
}