import { makeTableSortable } from '/js/sorting.js';

export function initOneDrive() {
    const driveSelect = document.getElementById("driveSelect");
    const oneDriveTable = document.getElementById("oneDriveTable").querySelector("tbody");
    const breadcrumb = document.getElementById("oneDriveBreadcrumb");
    let currentDrive = null;
    let currentFolder = null;
    let breadcrumbStack = [];

    // Helper: update breadcrumb UI
    function renderBreadcrumb() {
        breadcrumb.innerHTML = "";

        const rootSpan = document.createElement("span");
        rootSpan.textContent = "Root";
        rootSpan.classList.add("breadcrumb-link");
        rootSpan.addEventListener("click", async () => {
            breadcrumbStack = [];
            currentFolder = null;
            await loadOneDriveItems();
        });
        breadcrumb.appendChild(rootSpan);

        if (breadcrumbStack.length > 0) {
            breadcrumb.appendChild(document.createTextNode(" / "));
        }

        breadcrumbStack.forEach((bc, index) => {
            const span = document.createElement("span");
            span.textContent = bc.name;
            span.classList.add("breadcrumb-link");
            span.addEventListener("click", async () => {
                breadcrumbStack = breadcrumbStack.slice(0, index + 1);
                currentFolder = bc.id;
                await loadOneDriveItems(bc.id);
            });
            breadcrumb.appendChild(span);
            if (index < breadcrumbStack.length - 1) {
                breadcrumb.appendChild(document.createTextNode(" / "));
            }
        });
    }

    async function loadOneDriveItems(itemId = null) {
        document.getElementById("loadDrives").disabled = true;
        document.getElementById("goRoot").disabled = true;
        try {
            const user = document.getElementById("userSelect").value;
            if (!user || !currentDrive) return;

            const res = await fetch(
                `/api/onedrive/items?user=${encodeURIComponent(user)}&drive=${encodeURIComponent(currentDrive)}${itemId ? `&item=${itemId}` : ""}`
            );
            let items = await res.json();
            if (!Array.isArray(items)) items = items ? [items] : [];

            oneDriveTable.innerHTML = "";
            if (items.length === 0) {
                oneDriveTable.innerHTML = `<tr><td colspan="5">No items found</td></tr>`;
                renderBreadcrumb();
                return;
            }

            items.forEach(i => {
                const iname = i.name || i.Name || i.File?.Name || i.Folder?.Name || "(Unnamed)";
                const isFolder = i.Type === "Folder";
                const tr = document.createElement("tr");

                tr.innerHTML = `
                <td>${iname}</td>
                <td>${isFolder ? "Folder" : "File"}</td>
                <td>${isFolder ? "" : (i.SizeKB)}</td>
                <td>${i.lastModifiedDateTime || i.LastModified || ""}</td>
                <td>
                    ${!isFolder ? `
                        <button class="delete-btn" data-id="${i.Id}" data-name="${iname}">🗑️ Delete</button>
                        <button class="download-btn" data-id="${i.Id}">⬇️ Download</button>
                    ` : ""}
                </td>
                `;

                if (isFolder) {
                    tr.classList.add("folder-row");
                    tr.addEventListener("click", async () => {
                        currentFolder = i.Id;
                        breadcrumbStack.push({ id: i.Id, name: i.Name });
                        await loadOneDriveItems(i.Id);
                    });
                }

                oneDriveTable.appendChild(tr);
            });

            renderBreadcrumb();

            makeTableSortable(document.getElementById('signInTable'));
        } catch (err) {
            console.error('Error loading OneDrive drives:', err);
        } finally {
            document.getElementById('loadDrives').disabled = false;
            document.getElementById("goRoot").disabled = false;
        }
    }

    document.getElementById("loadDrives").addEventListener("click", async () => {
        document.getElementById("loadDrives").disabled = true;
        document.getElementById("goRoot").disabled = false;
        try {
            const user = document.getElementById("userSelect").value;
            if (!user) return alert("Select a user first.");

            const res = await fetch(`/api/onedrive/drives?user=${encodeURIComponent(user)}`);
            let drives = await res.json();
            if (!Array.isArray(drives)) drives = drives ? [drives] : [];

            driveSelect.innerHTML = "";
            drives.forEach(d => {
                const opt = document.createElement("option");
                opt.value = d.id || d.Id;
                opt.textContent = `${d.name || d.Name} (${d.driveType || d.DriveType})`;
                driveSelect.appendChild(opt);
            });

            if (drives.length > 0) {
                currentDrive = drives[0].id || drives[0].Id;
                currentFolder = null;
                breadcrumbStack = [];
                await loadOneDriveItems();
            }
        } catch (err) {
            console.error('Error loading OneDrive drives:', err);
        } finally {
            document.getElementById('loadDrives').disabled = false;
            document.getElementById("goRoot").disabled = false;
        }
    });

    oneDriveTable.addEventListener("click", async (e) => {
        const btn = e.target.closest(".delete-btn");
        if (!btn) return;

        const itemId = btn.dataset.id;
        const name = btn.dataset.name;

        if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;

        try {
            const user = document.getElementById("userSelect").value;

            const res = await fetch(
                `/api/onedrive/item?user=${encodeURIComponent(user)}&driveId=${encodeURIComponent(currentDrive)}&itemId=${encodeURIComponent(itemId)}`,
                { method: "DELETE" }
            );

            const result = await res.json();

            if (!res.ok) throw new Error(result.error || "Delete failed");

            // refresh current folder
            await loadOneDriveItems(currentFolder);

        } catch (err) {
            console.error("Delete failed:", err);
            alert("Failed to delete file");
        }
    });

    oneDriveTable.addEventListener("click", (e) => {
        const btn = e.target.closest(".download-btn");
        if (!btn) return;

        const itemId = btn.dataset.id;
        const user = document.getElementById("userSelect").value;

        const url =
            `/api/onedrive/download?user=${encodeURIComponent(user)}&driveId=${encodeURIComponent(currentDrive)}&itemId=${encodeURIComponent(itemId)}`;

        window.open(url, "_blank");
    });

    document.getElementById("driveSelect").addEventListener("change", e => {
        currentDrive = e.target.value;
        currentFolder = null;
        breadcrumbStack = [];
        loadOneDriveItems();
    });

    document.getElementById("goRoot").addEventListener("click", () => {
        currentFolder = null;
        breadcrumbStack = [];
        loadOneDriveItems();
    });
}