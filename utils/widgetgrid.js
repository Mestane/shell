.pragma library

// Geometry shared by the desktop widgets and the settings editor that arranges them: a square grid of `unit` px
// cells, and widgets that snap to it. Sizes are in cells.

const unit = 40;
// Space left between a card and the edge of its footprint, so neighbours never touch
const gap = 8;
// Every card is the same width; the height depends on what it shows
const cardCells = 8;
// Distance from the screen edge, and between the default columns, in cells
const margin = 2;

const heights = {
    calendar: 8,
    weather: 7,
    pomodoro: 5,
    resources: 5,
    media: 5,
    battery: 4
};

function heightOf(id) {
    return heights[id] ?? 5;
}

// Where each widget sits, parallel to `entries` ([{ id, enabled, col, row }]). Widgets that have been placed keep
// their cell (kept on screen); the rest flow into `columns` columns from the `position` corner, the way the desktop
// laid them out before they could be moved.
function place(entries, gridCols, gridRows, columns, position) {
    const out = entries.map(e => {
        const placed = e.col >= 0 && e.row >= 0;
        const w = cardCells;
        const h = heightOf(e.id);
        return {
            id: e.id,
            enabled: e.enabled,
            placed: placed,
            w: w,
            h: h,
            col: placed ? Math.max(0, Math.min(e.col, gridCols - w)) : 0,
            row: placed ? Math.max(0, Math.min(e.row, gridRows - h)) : 0
        };
    });

    const flow = out.filter(p => p.enabled && !p.placed);
    if (flow.length === 0)
        return out;

    const ncols = Math.max(1, columns);
    const heightsSoFar = new Array(ncols).fill(0);
    const colOf = [];
    flow.forEach((p, i) => {
        const c = i % ncols;
        colOf.push(c);
        p.row = heightsSoFar[c];
        heightsSoFar[c] += p.h + 1;
    });

    const totalW = ncols * (cardCells + 1) - 1;
    const x0 = position.endsWith("right") ? gridCols - margin - totalW : margin;
    const tallest = Math.max(...heightsSoFar) - 1;
    const y0 = position.startsWith("bottom") ? gridRows - margin - tallest : margin;

    flow.forEach((p, i) => {
        p.col = Math.max(0, x0 + colOf[i] * (cardCells + 1));
        p.row = Math.max(0, y0 + p.row);
    });
    return out;
}

// Does a w x h widget at (col, row) overlap any enabled widget other than the one at `skip`?
function collides(placements, skip, col, row, w, h) {
    for (let i = 0; i < placements.length; i++) {
        const p = placements[i];
        if (i === skip || !p.enabled)
            continue;
        if (col < p.col + p.w && col + w > p.col && row < p.row + p.h && row + h > p.row)
            return true;
    }
    return false;
}
