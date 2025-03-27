(function() {
var scrollTimer = 0;
let buffer = 4;

let bufferX = 0;
let bufferY = 0;

let table = null;

let lastpos1row = 0;
let lastpos1col = 0;

let lastpos2row = 0;
let lastpos2col = 0;

let minScrollTime = 300;
let samples = [];
const maxSamples = 10;
let scrollTimeout;
document.addEventListener("DOMContentLoaded", () => {
    table = document.getElementById("myTable");

    window.addEventListener("scroll", (event) => {
        calculateViewport();
      });
    window.addEventListener("resize",(event) =>{
        processScroll();
    });
    setTimeout(() => {processScroll();},1000);
    console.log("calculating visible rows..")
});

function getAverageSpeed(samples) {
    let totalDX = 0, totalDY = 0, totalDT = 0;
    for (let i = 1; i < samples.length; i++) {
      const dx = samples[i].x - samples[i - 1].x;
      const dy = samples[i].y - samples[i - 1].y;
      const dt = samples[i].t - samples[i - 1].t;
      if (dt > 0) {
        totalDX += dx;
        totalDY += dy;
        totalDT += dt;
      }
    }

    return {
      x: (totalDT > 0) ? (totalDX / totalDT) : 0, // px/s
      y: (totalDT > 0) ? (totalDY / totalDT) : 0
    };
}

function calculateViewport(){
    const t = performance.now();
    const x = window.scrollX;
    const y = window.scrollY;
    samples.push({ x, y, t });
    if (samples.length > maxSamples) samples.shift();
  
    if (samples.length < 5) return;
  
    const avgSpeed = getAverageSpeed(samples);

    bufferX = speedToValue(avgSpeed.x);
    bufferY = speedToValue(avgSpeed.y);
    console.log(bufferX, bufferY);

    clearTimeout(scrollTimeout);
    scrollTimeout = setTimeout(() => {
      console.log("Scrolling stopped");
      bufferX = bufferY = 0;
      processScroll();
    }, 500);
    if (Math.abs(bufferX) > 30 || Math.abs(bufferY) > 30){
        return;
    }
    if (!scrollTimer) {
        scrollTimer = setTimeout(function() {
            samples = [];
            scrollTimer = null;
            processScroll();
        }, minScrollTime);
    }
}
function speedToValue(speed) {
    const maxSpeed = 30; 
    const normalized = Math.min(Math.log2(1 + Math.abs(speed)) / Math.log2(1 + maxSpeed), 1) * Math.sign(speed);
    return Math.round(normalized * 100);
}

const isElementInViewport = function(el) {
    let
    rect = el.getBoundingClientRect(),
    windowHeight = (window.innerHeight || document.documentElement.clientHeight);  
    return !(
      Math.floor(100 - (((rect.top >= 0 ? 0 : rect.top) / +-rect.height) * 100)) < 5 ||
      Math.floor(100 - ((rect.bottom - windowHeight) / rect.height) * 100) < 5
    )

};

const isColumnVisible = function(el) {
    let rect = el.getBoundingClientRect();
    windowWidth = (window.innerWidth || document.documentElement.clientWidth);  
    return rect.left - rect.width >= 0 && rect.left < windowWidth;
}

function checkRowsInView(){
    let firstVisible = -1;
    for (var i = 0, row; row = table.rows[i]; i++) {
        if(isElementInViewport(row)){
            if (firstVisible === -1){
                firstVisible = i - 1;
            }
        }
        else{
            if (firstVisible !== -1){
                return {first:firstVisible, last:i-2};
            }
        }
    }   
    return {first:firstVisible, last:table.rows.length};
}

function checkColsInView(){
    let firstVisible = -1;
    for (var i = 0, col; col = table.rows[0].cells[i]; i++) {
        if(isColumnVisible(col)){
            if (firstVisible === -1){
                firstVisible = i - 1;
            }
        }
        else{
            if (firstVisible !== -1){
                return {first:firstVisible, last:i-2};
            }
        }
    }   
    return {first:firstVisible, last:table.rows[0].cells.length};
}


function processScroll() {
    var visibleRows = checkRowsInView();
    var visibleCols = checkColsInView();

    var pos1Row = Math.max(0,(visibleRows.first - buffer) + Math.ceil(((visibleRows.last - visibleRows.first) * bufferY) / 100));
    var pos1Col = Math.max(0,(visibleCols.first - buffer) + Math.ceil(((visibleCols.last - visibleCols.first) * bufferX) / 100));

    var pos2Row = Math.max(0,visibleRows.last + buffer + Math.ceil(((visibleRows.last - visibleRows.first) * bufferY) / 100));
    var pos2Col = Math.max(0,visibleCols.last + buffer + Math.ceil(((visibleCols.last - visibleCols.first) * bufferX) / 100));
    if (!(lastpos1row == pos1Row && lastpos2row == pos2Row && lastpos1col == pos1Col && lastpos2col == pos2Col)){
        console.log({value1: pos1Row + "," + pos1Col, value2:pos2Row + "," + pos2Col});
        $salix.send({"name":"targetValues","handle":{"id":3,"maps":[]}}, 
            {value1: pos1Row + "," + pos1Col, value2:pos2Row + "," + pos2Col});
        lastpos1row = pos1Row;
        lastpos1col = pos1Col;

        lastpos2row = pos2Row;
        lastpos2col = pos2Col;
    }

}
})();
