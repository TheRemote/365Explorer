import { makeTableSortable } from '/js/sorting.js';

export function initEmail() {
    const mailRange = document.getElementById('mailRange');
    const mailValue = document.getElementById('mailValue');
    mailRange.addEventListener('input', () => {
        mailValue.textContent = mailRange.value;
    });

    document.getElementById('loadEmails').addEventListener('click', loadEmails);
}

async function loadEmails() {
    const user = document.getElementById('userSelect').value;
    if (!user) return alert('Please select a user first.');

    const mailcount = document.getElementById('mailRange').value;
    const subject = document.getElementById('subjectSearch').value;
    const start = document.getElementById('startDate').value;
    const end = document.getElementById('endDate').value;

    const params = new URLSearchParams({ user, mailcount });
    if (subject) params.append('subject', subject);
    if (start) params.append('start', start);
    if (end) params.append('end', end);

    document.getElementById('loadEmails').disabled = true;
    try {
        const res = await fetch(`/api/emails?${params.toString()}`);
        const data = await res.json();

        const emails = Array.isArray(data) ? data : [data];

        const tbody = document.querySelector('#emailTable tbody');
        tbody.innerHTML = '';

        emails.forEach(email => {
            const attachmentsArray = email.Attachments
                ? (Array.isArray(email.Attachments) ? email.Attachments : [email.Attachments])
                : [];

            const attachmentsHTML = attachmentsArray.length > 0
                ? attachmentsArray.map(a =>
                    `<a href="${a.WebLink}" target="_blank">${a.Name}</a> (${(a.Size / 1024).toFixed(1)} KB)`
                ).join('<br>')
                : '';

            const tr = document.createElement('tr');
            tr.innerHTML = `
            <td>${email.Folder || ''}</td>
            <td>${email.Subject || '(no subject)'}</td>
            <td>${email.From || ''}</td>
            <td>${email.To || ''}</td>
            <td>${new Date(email.SentDateTime).toLocaleString()}</td>
            <td>${attachmentsHTML}</td>
            <td>${email.BodyPreview || ''}</td>
            <td><button class="delete-btn" data-id="${email.Id}">🗑️ Delete</button></td>
        `;

            // body click handler
            tr.addEventListener('click', (event) => {
                if (event.target.tagName === 'A' || event.target.classList.contains('delete-btn')) return;
                document.getElementById('body').innerHTML = email.Body;

                const headerInfo = [];
                headerInfo.push(`Folder: ${email.Folder || ''}`);
                headerInfo.push(`Subject: ${email.Subject || ''}`);
                headerInfo.push(`From: ${email.From || ''}`);
                headerInfo.push(`To: ${email.To || ''}`);
                if (email.ReplyTo) headerInfo.push(`Reply-To: ${email.ReplyTo}`);
                if (email.ReplyTo) headerInfo.push(`Return-Path: ${email.ReturnPath}`);

                if (attachmentsArray.length > 0) {
                    const attachmentList = attachmentsArray.map(att => {
                        const sizeKB = (att.Size / 1024).toFixed(1);
                        return `<li><a href="${att.WebLink}" target="_blank">${att.Name}</a> (${sizeKB} KB)</li>`;
                    }).join('');
                    headerInfo.push(`Attachments:<ul>${attachmentList}</ul>`);
                }

                if (email.InternetMessageHeaders?.length) {
                    headerInfo.push("<hr><pre>" +
                        email.InternetMessageHeaders.map(h => `${h.Name}: ${h.Value}`).join('\n') +
                        "</pre>");
                }

                document.getElementById('headers').innerHTML = headerInfo.join('<br>');
                document.querySelector('.tab-btn[data-tab="bodyTab"]').click();
            });

            // delete button
            tr.querySelector('.delete-btn').addEventListener('click', async (e) => {
                e.stopPropagation();
                if (!confirm(`Delete email "${email.Subject}"?`)) return;

                const delRes = await fetch(`/api/email?user=${encodeURIComponent(user)}&id=${encodeURIComponent(email.Id)}`, {
                    method: 'DELETE'
                });

                if (delRes.ok) {
                    tr.remove();
                } else {
                    const err = await delRes.json();
                    alert('Error deleting email: ' + (err.error || delRes.statusText));
                }
            });

            tbody.appendChild(tr);
        });

        makeTableSortable(document.getElementById('emailTable'));
    } catch (err) {
        console.error('Error loading emails:', err);
    } finally {
        document.getElementById('loadEmails').disabled = false;
    }
}