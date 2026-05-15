export function initAccount() {
    const loadBtn = document.getElementById('loadAccount');
    const enableBtn = document.getElementById('enableAccount');
    const disableBtn = document.getElementById('disableAccount');
    const signOutBtn = document.getElementById('signOutAccount');

    if (loadBtn) loadBtn.addEventListener('click', loadAccount);
    if (enableBtn) enableBtn.addEventListener('click', enableAccount);
    if (disableBtn) disableBtn.addEventListener('click', disableAccount);
    if (signOutBtn) signOutBtn.addEventListener('click', signOutAccount);

    // --- Tab Switching Logic ---
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById(btn.dataset.tab).classList.add('active');
        });
    });
}


// Load account info
async function loadAccount() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');
    document.getElementById('loadAccount').disabled = true;
    let account; 
    try {
        const res = await fetch(`/api/account?user=${encodeURIComponent(user)}`);
        account = await res.json();
    } catch (err) {
        console.error('Error loading account:', err);
        return;
    } finally {
        document.getElementById('loadAccount').disabled = false;
    }

    const container = document.getElementById('accountInfo');
    container.innerHTML = '';

    // Define groups and their fields
    const groups = {
        'Basic Info': ['Enabled', 'DisplayName', 'UserPrincipalName', 'UserId', 'OnPremisesSyncEnabled', 'Mail', 'UserType', 'PreferredLanguage', 'JobTitle', 'OfficeLocation', 'Department', 'CompanyDomain'],
        'Security': ['PasswordChanged', 'SignInSessionsValidFrom', 'CreatedDateTime', 'LastSignInDate', 'LastNonInteractiveSignIn', 'PasswordPolicies', 'UsageLocation'],
        'Exchange': ['MailboxType', 'PrimarySmtpAddress', 'ProxyAddresses', 'ForwardingAddress', 'HiddenFromGAL', 'LitigationHoldEnabled', 'RetentionPolicy', 'ItemCount', 'DeletedItemCount', 'MailboxSizeMB', 'MailboxQuotaMB', 'ArchiveStatus', 'ArchiveItemCount', 'ArchiveSizeMB', 'ArchiveQuotaMB'],
        'Licensing': ['IsLicensed', 'LicenseCount', 'Licensing', 'AssignedPlans']
    };

    // Create sections for each group
    for (const [groupName, fields] of Object.entries(groups)) {
        const groupDiv = document.createElement('div');
        groupDiv.innerHTML = `<h3>${groupName}</h3>`;
        const fieldsDiv = document.createElement('div');
        fieldsDiv.classList.add('account-field-group');

        fields.forEach(field => {
            if (account[field] !== undefined) {
                const fieldDiv = document.createElement('div');
                fieldDiv.classList.add('account-field');

                const label = document.createElement('label');
                label.textContent = field;
                label.htmlFor = field;

                const input = document.createElement('textarea');
                //input.type = 'text';
                input.disabled = true;
                input.id = field;
                input.value = account[field] ?? '';

                fieldDiv.appendChild(label);
                fieldDiv.appendChild(input);
                fieldsDiv.appendChild(fieldDiv);
            }
        });

        groupDiv.appendChild(fieldsDiv);
        container.appendChild(groupDiv);
    }

    // Add any remaining fields under "Other"
    const otherFields = Object.keys(account).filter(key => !Object.values(groups).flat().includes(key));
    if (otherFields.length > 0) {
        const otherDiv = document.createElement('div');
        otherDiv.innerHTML = '<h3>Other</h3>';
        const fieldsDiv = document.createElement('div');
        fieldsDiv.classList.add('account-field-group');

        otherFields.forEach(field => {
            const fieldDiv = document.createElement('div');
            fieldDiv.classList.add('account-field');

            const label = document.createElement('label');
            label.textContent = field;
            label.htmlFor = field;

            const input = document.createElement('input');
            input.type = 'text';
            input.disabled = true;
            input.id = field;
            input.value = account[field] ?? '';

            fieldDiv.appendChild(label);
            fieldDiv.appendChild(input);
            fieldsDiv.appendChild(fieldDiv);
        });

        otherDiv.appendChild(fieldsDiv);
        container.appendChild(otherDiv);
    }
}

async function disableAccount() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');
    if (!confirm(`Are you sure you want to block sign-in / disable ${user}?`)) return;
    document.getElementById('disableAccount').disabled = true;
    try {
        const res = await fetch(`/api/disableuser?user=${encodeURIComponent(user)}`);
        await res.text();
        loadAccount();
    } catch (err) {
        console.error('Error disabling account:', err);
    } finally {
        document.getElementById('disableAccount').disabled = false;
    }
}

async function enableAccount() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');
    if (!confirm(`Are you sure you want to enable sign-in for ${user}?`)) return;
    document.getElementById('enableAccount').disabled = true;
    try {
        const res = await fetch(`/api/enableuser?user=${encodeURIComponent(user)}`);
        await res.text();
        loadAccount();
    } catch (err) {
        console.error('Error enabling account:', err);
    } finally {
        document.getElementById('enableAccount').disabled = false;
    }
}

async function signOutAccount() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');
    if (!confirm(`Are you sure you want to sign out all sessions for ${user}?`)) return;
    document.getElementById('signOutAccount').disabled = true;
    try {
        const res = await fetch(`/api/signOutUser?user=${encodeURIComponent(user)}`);
        await res.text();
        loadAccount();
    } catch (err) {
        console.error('Error signing out account:', err);
    } finally {
        document.getElementById('signOutAccount').disabled = false;
    }

}

export async function getUsers() {
    const res = await fetch('/api/users');
    const users = await res.json();
    const select = document.getElementById('userSelect');
    select.innerHTML = '';
    users.forEach(u => {
        const opt = document.createElement('option');
        opt.value = u.Id;
        opt.text = `${u.DisplayName} (${u.UserPrincipalName})`;
        select.appendChild(opt);
    });
}