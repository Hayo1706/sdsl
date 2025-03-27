document.addEventListener("DOMContentLoaded", function() {
    const body   = document.body;

    const THRESH  = 10;  // px from border
    let mode = target = line = rect = null;

    //Move bar and show mouse icon
    document.addEventListener('mousemove', e => {
        if (mode) {
            if (line){
                console.log(e);
                if (mode === 'col') line.style.left = e.clientX + 'px';
                else line.style.top  = e.clientY + 'px';
            }
            table.style.cursor = mode === 'col' ? 'col-resize' : 'row-resize';
        } else {
            const info = getResizeInfo(e);
            table.style.cursor = info ? (info.mode === 'col' ? 'col-resize' : 'row-resize') : '';
        }
    });

    // Begin dragging
    document.addEventListener('mousedown', e => {
        const info = getResizeInfo(e);
        if (!info || !table) return;
        mode    = info.mode;
        target  = info.target;
        rect = info.rect;

        e.preventDefault();
        createLine(mode, mode === 'col' ? e.clientX : e.clientY);
    });

    function createLine(m, pos) {
        line = document.createElement('div');
        line.className = 'resizing-line';
        const tblRect = table.getBoundingClientRect();
        if (m === 'col') {
            line.style.left   = pos + 'px';
            line.style.top    = tblRect.top + 'px';
            line.style.height = tblRect.height + 'px';
        } else {
            line.style.left   = tblRect.left + 'px';
            line.style.top    = pos + 'px';
            line.style.width  = tblRect.width + 'px';
        }
        document.body.appendChild(line);
    }

    function getResizeInfo(e) {
        const th = e.target.closest('th');
        if (!th) return null;
        const rect = th.getBoundingClientRect();
        // Are we near a THEAD column edge?
        if (th.parentNode.parentNode.tagName === 'THEAD'){
            if(Math.abs(rect.right - e.clientX) < THRESH){
                return { mode: 'col', target: th, rect: rect};
            }
            var prevSibling = th.previousElementSibling;
            if (Math.abs(rect.left - e.clientX) < THRESH && prevSibling){
                return { mode: 'col', target: prevSibling , rect: prevSibling.getBoundingClientRect()};
            }
        }
            
        // Or near a TBODY row edge (first column only)?
        if (th.parentNode.parentNode.tagName === 'TBODY') {
            if(th.cellIndex === 0 && Math.abs(rect.bottom - e.clientY) < THRESH)
                return { mode: 'row', target: th.parentNode, rect: rect };
                var prevRow = th.parentElement.previousElementSibling;
                var prevCell = prevRow?.children[th.cellIndex];
            if (th.cellIndex === 0 && Math.abs(rect.top - e.clientY) < THRESH && prevCell){
                var prevCell = th.parentElement.previousElementSibling.children[th.cellIndex];
                return { mode: 'row', target: prevRow, rect: prevCell.getBoundingClientRect() };
            }
        }
    }

    // Finalize on mouseup
    document.addEventListener('mouseup', e => {
        if (!mode || !target || !line) return;
        
        var computedStyle = getComputedStyle(target);
        elementHeight = target.clientHeight;  // height with padding
        elementWidth = target.clientWidth;   // width with padding

        elementHeight -= parseFloat(computedStyle.paddingTop) + parseFloat(computedStyle.paddingBottom);
        elementWidth -= parseFloat(computedStyle.paddingLeft) + parseFloat(computedStyle.paddingRight);

        if (mode === 'col') 
            target.style.width = Math.max((elementWidth + (parseFloat(line.style.left) - rect.right)) + 1, 10) + 'px';
        else 
            target.style.height = Math.max((elementHeight + (parseFloat(line.style.top) - rect.bottom)) + 1, 10) + 'px';

        document.body.removeChild(line);
        mode = target = line = rect = th = null;
        //resize the input if its set in the resized column
        drawInput()
    });

    document.addEventListener("mousemove", (e) => e.preventDefault()); // Stops dragging behavior
});