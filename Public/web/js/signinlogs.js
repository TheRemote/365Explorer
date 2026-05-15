import { makeTableSortable } from '/js/sorting.js';

export function initSignInLogs() {
    document.getElementById('loadSignInLogs').addEventListener('click', loadSignInLogs);
    const dlBtn = document.getElementById('downloadSignInCsvBtn');
    dlBtn.style.display = 'inline-block';
    dlBtn.onclick = () => {
        const csv = tableToCSV('signInTable');
        downloadCSV(`signin-logs.csv`, csv);
    };

    const daysRange = document.getElementById('daysRange');
    const daysValue = document.getElementById('daysValue');
    daysRange.addEventListener('input', () => {
        daysValue.textContent = daysRange.value;
    });
}


async function loadSignInLogs() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');

    const days = parseInt(document.getElementById('daysRange').value);
    const loadButton = document.getElementById('loadSignInLogs');
    const tbody = document.querySelector('#signInTable tbody');
    const progressText = document.getElementById('progressText');
    const progressBar = document.getElementById('progressBar');

    loadButton.disabled = true;
    tbody.innerHTML = '';
    progressText.textContent = `Loading 0 of ${days} days...`;
    progressBar.value = 0;
    progressBar.max = days;
    progressBar.style.display = 'block';

    // Newest → Oldest
    for (let i = 0; i < days; i++) {
        const end = new Date();
        end.setDate(end.getDate() - i);
        const start = new Date();
        start.setDate(end.getDate() - 1);

        const startIso = start.toISOString();
        const endIso = end.toISOString();

        try {
            const res = await fetch(`/api/signInLogs?user=${encodeURIComponent(user)}&start=${encodeURIComponent(startIso)}&end=${encodeURIComponent(endIso)}`);
            const logs = await res.json();

            if (Array.isArray(logs) && logs.length > 0) {
                logs.forEach(signin => {
                    const tr = document.createElement('tr');
                    tr.innerHTML = `
                        <td>${signin.CreatedDateTime}</td>
                        <td>${signin.AppDisplayName}</td>
                        <td>${signin.ResourceDisplayName}</td>
                        <td>${signin.ClientAppUsed}</td>
                        <td>${signin.IsInteractive}</td>
                        <td>${signin.IPAddress}</td>
                        <td>${signin.City}</td>
                        <td>${signin.State}</td>
                        <td>${signin.CountryOrRegion}</td>
                        <td>${signin.StatusDetail}</td>
                        <td>${signin.StatusErrorCode}</td>
                        <td>${signin.StatusFailureReason}</td>
                        <td>${signin.ConditionalAccessPolicies}</td>
                        <td>${signin.ConditionalAccessStatus}</td>
                        <td>${signin.DeviceBrowser}</td>
                        <td>${signin.DeviceOperatingSystem}</td>
                        <td>${signin.DeviceName}</td>
                        <td>${signin.DeviceIsCompliant}</td>
                        <td>${signin.DeviceIsManaged}</td>
                        <td>${signin.DeviceTrust}</td>
                        <td>${signin.UserDisplayName}</td>
                        <td>${signin.UserPrincipalName}</td>
                        <td>${signin.AppId}</td>
                        <td>${signin.CorrelationId}</td>
                        <td>${signin.DeviceId}</td>
                        <td>${signin.Id}</td>
                        <td>${signin.UserId}</td>
                        <td>${signin.ResourceId}</td>
                    `;
                    tbody.appendChild(tr);
                });
            }

            makeTableSortable(document.getElementById('signInTable'));

            const daysLoaded = i + 1;
            progressText.textContent = `Loaded ${daysLoaded} of ${days} days`;
            progressBar.value = daysLoaded;

            await new Promise(resolve => setTimeout(resolve, 100));
        } catch (err) {
            console.error('Error fetching logs:', err);
        }
    }

    progressText.textContent = `Completed loading ${days} days of logs.`;
    loadButton.disabled = false;
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

            if (text === '' || text === 'null' || text === 'undefined') {
                text = '';
            }

            text = text.replace(/"/g, '""'); // escape quotes

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