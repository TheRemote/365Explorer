import { initRules } from '/js/rules.js';
import { initAccount } from '/js/account.js';
import { getUsers } from '/js/account.js';
import { initEmail } from '/js/email.js';
import { initMFA } from '/js/mfa.js';
import { initSignInLogs } from '/js/signinlogs.js';
import { initAuditLogs } from '/js/auditlogs.js';
import { initOneDrive } from '/js/onedrive.js';

document.addEventListener('DOMContentLoaded', () => {
    initAuditLogs();
    initSignInLogs();
    initRules();
    initAccount();
    initEmail();
    initMFA();
    initOneDrive();

    getUsers();
});