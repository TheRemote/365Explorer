import { makeTableSortable } from '/js/sorting.js';

export function initAuditLogs() {
    document.getElementById('loadAuditLogs').addEventListener('click', loadAuditLogs);

    // Attach click event
    document.getElementById('downloadCsvBtn').onclick = () => {
        const csv = tableToCSV('auditTable');
        downloadCSV(`audit-logs.csv`, csv);
    };

    const daysRangeAudit = document.getElementById('daysRangeAudit');
    const daysValueAudit = document.getElementById('daysValueAudit');
    daysRangeAudit.addEventListener('input', () => {
        daysValueAudit.textContent = daysRangeAudit.value;
    });
}

async function loadAuditLogs() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');

    const days = parseInt(document.getElementById('daysRangeAudit').value);
    const CHUNK_HOURS = 2;

    const loadBtn = document.getElementById('loadAuditLogs');
    const tbody = document.querySelector('#auditTable tbody');
    const thead = document.querySelector('#auditTable thead');
    const progressText = document.getElementById('auditProgressText');
    const progressBar = document.getElementById('auditProgressBar');

    loadBtn.disabled = true;
    tbody.innerHTML = '';
    thead.innerHTML = '';
    progressBar.value = 0;
    progressBar.max = days * (24 / CHUNK_HOURS);
    progressBar.style.display = 'block';
    progressText.textContent = `Loading 0 of ${days} days...`;

    let allKeys = new Set();
    let headerBuilt = false;
    let previousKeyCount = 0;
    let chunkCount = 0;

    for (let i = 0; i < days; i++) {
        const dayEnd = new Date();
        dayEnd.setHours(23, 59, 59, 999);
        dayEnd.setDate(dayEnd.getDate() - i);

        const dayStart = new Date(dayEnd);
        dayStart.setHours(0, 0, 0, 0);

        for (let h = 0; h < 24; h += CHUNK_HOURS) {
            const start = new Date(dayStart);
            start.setHours(h);

            const end = new Date(start);
            end.setHours(h + CHUNK_HOURS);

            const startIso = start.toISOString();
            const endIso = end.toISOString();

            try {
                const res = await fetch(`/api/auditLogs?user=${encodeURIComponent(user)}&start=${encodeURIComponent(startIso)}&end=${encodeURIComponent(endIso)}`);
                const logs = await res.json();

                if (Array.isArray(logs) && logs.length > 0) {
                    logs.forEach(log => Object.keys(log).forEach(k => allKeys.add(k)));

                    // Build header if not built or if new keys found
                    if (!headerBuilt || allKeys.size !== previousKeyCount) {
                        thead.innerHTML = '';
                        const headerRow = document.createElement('tr');

                        for (const key of allKeys) {
                            const th = document.createElement('th');
                            th.textContent = key;
                            headerRow.appendChild(th);
                        }

                        thead.appendChild(headerRow);
                        previousKeyCount = allKeys.size;
                        headerBuilt = true;
                    }

                    // Append logs
                    logs.forEach(log => {
                        const tr = document.createElement('tr');
                        for (const key of allKeys) {
                            const td = document.createElement('td');
                            let val = log[key];
                            if (val === null || val === undefined) val = 'null';
                            td.textContent = val;
                            tr.appendChild(td);
                        }
                        tbody.append(tr);
                    });
                }

                makeTableSortable(document.getElementById('auditTable'));

                chunkCount++;
                progressText.textContent = `Loaded chunk ${chunkCount} of ${progressBar.max}`;
                progressBar.value = chunkCount;

                await new Promise(resolve => setTimeout(resolve, 100));
            } catch (err) {
                console.error('Error fetching audit logs:', err);
            }
        }
    }

    progressText.textContent = `Completed loading ${days} days of audit logs (${chunkCount} chunks).`;
    loadBtn.disabled = false;
}

function tableToCSV(tableId) {
    const table = document.getElementById(tableId);
    const rows = table.querySelectorAll('tr');
    let csv = [];

    for (const row of rows) {
        const cols = row.querySelectorAll('th, td');
        let rowData = [];

        cols.forEach(cell => {
            let text = cell.textContent.trim();

            // Normalize nulls
            if (text === '' || text === 'null' || text === 'undefined') {
                text = '';
            }

            // Escape quotes by doubling them
            text = text.replace(/"/g, '""');

            // Wrap fields containing commas or quotes
            if (text.includes(',') || text.includes('"')) {
                text = `"${text}"`;
            }

            rowData.push(text);
        });

        csv.push(rowData.join(','));
    }

    return csv.join('\n');
}

function downloadCSV(filename, csvText) {
    const blob = new Blob([csvText], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);

    link.href = url;
    link.download = filename;
    link.style.display = 'none';

    document.body.appendChild(link);
    link.click();

    document.body.removeChild(link);
    URL.revokeObjectURL(url);
}