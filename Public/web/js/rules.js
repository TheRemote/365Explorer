export function initRules() {
    const btn = document.getElementById('loadRules');
    if (btn) btn.addEventListener('click', loadRules);
}

async function loadRules() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');
    document.getElementById('loadRules').disabled = true;
    try {
        const res = await fetch(`/api/mailrules?user=${encodeURIComponent(user)}`);
        const rules = await res.json();
        const tbody = document.querySelector('#rulesTable tbody');
        tbody.innerHTML = '';

        if (!rules || (Array.isArray(rules) && rules.length === 0)) {
            const tr = document.createElement('tr');
            tr.innerHTML = `<td colspan="6">(no rules found)</td>`;
            tbody.appendChild(tr);
            return;
        }

        (Array.isArray(rules) ? rules : [rules]).forEach(rule => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
          <td>${rule.Name || ''}</td>
          <td>${rule.Enabled ? 'Yes' : 'No'}</td>
          <td>${rule.Description || ''}</td>
          <td>${rule.From || ''}</td>
          <td>${rule.RedirectTo || ''}</td>
          <td>${rule.ForwardTo || ''}</td>
          <td><button class="disableRuleBtn" data-ruleid="${rule.RuleIdentity}">Disable</button><button class="enableRuleBtn" data-ruleid="${rule.RuleIdentity}">Enable</button><button class="deleteRuleBtn" data-ruleid="${rule.RuleIdentity}">🗑️ Delete</button></td>
        `;
            tbody.appendChild(tr);
        });

        // Attach delete handlers
        document.querySelectorAll('.deleteRuleBtn').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                const ruleId = btn.dataset.ruleid;
                const user = document.getElementById('userSelect').value;
                if (!confirm('Are you sure you want to delete this rule?')) return;

                btn.disabled = true;
                const res = await fetch(`/api/mailrule?user=${encodeURIComponent(user)}&ruleid=${encodeURIComponent(ruleId)}`, {
                    method: 'DELETE'
                });
                btn.disabled = false;

                if (res.ok) {
                    loadRules();
                } else {
                    const err = await res.text();
                    alert('Failed to delete rule: ' + err);
                }
            });
        });

        // Attach disable handlers
        document.querySelectorAll('.disableRuleBtn').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                const ruleId = btn.dataset.ruleid;
                const user = document.getElementById('userSelect').value;
                if (!confirm('Are you sure you want to disable this rule?')) return;

                btn.disabled = true;
                const res = await fetch(`/api/disablemailrule?user=${encodeURIComponent(user)}&ruleid=${encodeURIComponent(ruleId)}`);
                btn.disabled = false;

                if (res.ok) {
                    loadRules();
                } else {
                    const err = await res.text();
                    alert('Failed to disable rule: ' + err);
                }
            });
        });

        // Attach enable handlers
        document.querySelectorAll('.enableRuleBtn').forEach(btn => {
            btn.addEventListener('click', async (e) => {
                e.stopPropagation();
                const ruleId = btn.dataset.ruleid;
                const user = document.getElementById('userSelect').value;
                if (!confirm('Are you sure you want to enable this rule?')) return;

                const res = await fetch(`/api/enablemailrule?user=${encodeURIComponent(user)}&ruleid=${encodeURIComponent(ruleId)}`);

                if (res.ok) {
                    loadRules();
                } else {
                    const err = await res.text();
                    alert('Failed to enabled rule: ' + err);
                }
            });
        });

        document.querySelector('.tab-btn[data-tab="rulesTab"]').click();
    } catch (err) {
        console.error('Error retrieving rules:', err);
    } finally {
        document.getElementById('loadRules').disabled = false;
    }
}