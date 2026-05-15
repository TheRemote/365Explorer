export function initMFA() {
    document.getElementById('loadMFA').addEventListener('click', async () => {
        const user = document.getElementById('userSelect').value;
        if (!user) return alert('Please select a user first.');
        await loadMFA(user);
    });
}

async function loadMFA(user) {
    document.getElementById('loadMFA').disabled = true;
    const container = document.getElementById('MFAInfo');
    container.innerHTML = 'Loading...';
    try {
        const res = await fetch(`/api/mfa?user=${encodeURIComponent(user)}`);
        const data = await res.json();

        // Ensure data is always an array
        const methods = Array.isArray(data) ? data : [data];

        if (!methods || methods.length === 0) {
            container.textContent = '(No MFA methods found)';
            return;
        }

        const table = document.createElement('table');
        table.innerHTML = `
            <thead>
                <tr><th>Type</th><th>Detail</th><th>Action</th></tr>
            </thead>
            <tbody>
                ${methods.map(m => `
                    <tr data-id="${m.Id}" data-type="${m.RawType}">
                        <td>${m.Type}</td>
                        <td>${m.Detail}</td>
                        <td><button class="delete-mfa">🗑️ Delete</button></td>
                    </tr>
                `).join('')}
            </tbody>
        `;
        container.innerHTML = '';
        container.appendChild(table);

        table.querySelectorAll('.delete-mfa').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                const row = e.target.closest('tr');
                const id = row.dataset.id;
                const type = row.dataset.type;
                if (!confirm(`Delete MFA method '${row.children[0].textContent}'?`)) return;

                const res = await fetch(`/api/mfa?user=${encodeURIComponent(user)}&id=${encodeURIComponent(id)}&type=${encodeURIComponent(type)}`, {
                    method: 'DELETE'
                });
                const result = await res.json();

                if (result.success) {
                    row.remove();
                } else {
                    alert(`Failed to delete: ${result.error || 'Unknown error'}`);
                }
            });
        });
    } catch (err) {
        console.error('Error disabling account:', err);
    } finally {
        document.getElementById('loadMFA').disabled = false;
    }
}

