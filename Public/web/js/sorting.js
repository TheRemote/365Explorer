
export function makeTableSortable(table) {
    const headers = table.querySelectorAll('th');
    let lastSortedIndex = null;
    let lastDirection = 'asc';

    headers.forEach((header, index) => {
        header.style.cursor = 'pointer';
        header.addEventListener('click', () => {
            const tbody = table.querySelector('tbody');
            const rows = Array.from(tbody.querySelectorAll('tr'));

            // Toggle direction only if clicking same column
            let direction = 'asc';
            if (lastSortedIndex === index && lastDirection === 'asc') {
                direction = 'desc';
            }

            // Store new state
            lastSortedIndex = index;
            lastDirection = direction;

            // Clear all header arrows
            headers.forEach(h => h.textContent = h.textContent.replace(/ ▲| ▼/, ''));

            // Add arrow indicator
            header.textContent += direction === 'asc' ? ' ▲' : ' ▼';

            rows.sort((a, b) => {
                const cellA = a.children[index]?.innerText.trim().toLowerCase() ?? '';
                const cellB = b.children[index]?.innerText.trim().toLowerCase() ?? '';

                // Try to detect numbers or dates
                const dateA = Date.parse(cellA);
                const dateB = Date.parse(cellB);
                let valA = !isNaN(dateA) && cellA.match(/\d{4}/) ? dateA :
                           (!isNaN(parseFloat(cellA)) && cellA.match(/^\d+(\.\d+)?$/) ? parseFloat(cellA) : cellA);
                let valB = !isNaN(dateB) && cellB.match(/\d{4}/) ? dateB :
                           (!isNaN(parseFloat(cellB)) && cellB.match(/^\d+(\.\d+)?$/) ? parseFloat(cellB) : cellB);

                if (valA < valB) return direction === 'asc' ? -1 : 1;
                if (valA > valB) return direction === 'asc' ? 1 : -1;
                return 0;
            });

            // Re-append rows in sorted order
            rows.forEach(row => tbody.appendChild(row));
        });
    });
}
