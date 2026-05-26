// yt-channel dashboard — vanilla JS, no build step
// Talks to /__openclaw__/yt-channel/api/* (relative paths)

const API = "api";
const WS_URL = `${location.protocol === "https:" ? "wss" : "ws"}://${location.host}/__openclaw__/yt-channel/ws`;

const $stats = document.getElementById("stats");
const $runsTable = document.getElementById("runs-table");
const $nichesGrid = document.getElementById("niches-grid");
const $events = document.getElementById("events-log");
const $wsStatus = document.getElementById("ws-status");

const fmtCost = (n) => (n ?? 0).toFixed(2);
const escape = (s) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

async function fetchJson(path) {
	const r = await fetch(`${API}/${path}`, { cache: "no-store" });
	if (!r.ok) throw new Error(`${path} -> ${r.status}`);
	return r.json();
}

function renderStats(s) {
	const items = [
		{ label: "Runs", value: s.total_runs ?? 0 },
		{ label: "Running", value: s.running ?? 0, cls: "accent" },
		{ label: "Done", value: s.done ?? 0, cls: "ok" },
		{ label: "Failed", value: s.failed ?? 0, cls: "err" },
		{ label: "Niches", value: s.niches ?? 0 },
		{ label: "Cost €", value: fmtCost(s.total_cost_eur) },
	];
	$stats.innerHTML = items
		.map(
			(i) =>
				`<div class="stat"><div class="stat-label">${i.label}</div><div class="stat-value ${i.cls || ""}">${i.value}</div></div>`,
		)
		.join("");
}

function renderRuns(runs) {
	if (!runs.length) {
		$runsTable.innerHTML = '<div class="empty">no runs yet — click "+ new run"</div>';
		return;
	}
	const rows = runs
		.map((r) => {
			const stateBadge = `badge-${r.state}`;
			return `<tr>
				<td><code>${escape(r.id)}</code></td>
				<td>${escape(r.niche_slug || "-")}</td>
				<td><span class="badge ${stateBadge}">${escape(r.state)}</span></td>
				<td>${escape(r.current_stage || "-")}</td>
				<td>${fmtCost(r.cost_eur)}</td>
				<td class="dim">${escape(r.started_at)}</td>
			</tr>`;
		})
		.join("");
	$runsTable.innerHTML = `<table>
		<thead><tr><th>ID</th><th>Niche</th><th>State</th><th>Stage</th><th>€</th><th>Started</th></tr></thead>
		<tbody>${rows}</tbody>
	</table>`;
}

function renderNiches(niches) {
	if (!niches.length) {
		$nichesGrid.innerHTML = '<div class="empty">no niches yet — run niche-radar</div>';
		return;
	}
	$nichesGrid.innerHTML = `<div class="niches-grid">${niches
		.map(
			(n) => `<div class="niche-card">
				<div class="niche-name">${escape(n.name)}</div>
				<div class="niche-slug">${escape(n.slug)}</div>
				<div style="margin-top:8px">RPM ~ <span class="dim">$${n.rpm_estimate?.toFixed?.(2) ?? "?"}</span></div>
			</div>`,
		)
		.join("")}</div>`;
}

function appendEvent(ev) {
	const div = document.createElement("div");
	div.className = "event-line";
	const ts = ev.ts || new Date().toISOString();
	div.innerHTML = `<span class="event-ts">${escape(ts)}</span><span class="event-stage">${escape(ev.stage || "?")}</span><span>${escape(ev.event || "?")}</span> <code class="dim">${escape((ev.run_id || "").slice(-8))}</code>`;
	$events.prepend(div);
	while ($events.childElementCount > 200) $events.lastChild?.remove();
}

async function refresh() {
	try {
		const [s, r, n] = await Promise.all([
			fetchJson("summary"),
			fetchJson("runs"),
			fetchJson("niches"),
		]);
		renderStats(s);
		renderRuns(r.runs || []);
		renderNiches(n.niches || []);
	} catch (e) {
		console.error(e);
	}
}

function connectWs() {
	try {
		const ws = new WebSocket(WS_URL);
		ws.onopen = () => {
			$wsStatus.textContent = "live";
			$wsStatus.classList.add("live");
			$wsStatus.classList.remove("down");
		};
		ws.onmessage = (msg) => {
			try {
				const m = JSON.parse(msg.data);
				if (m.type === "stage_event") {
					appendEvent(m.payload);
					refresh();
				}
			} catch {}
		};
		ws.onclose = () => {
			$wsStatus.textContent = "disconnected — retrying";
			$wsStatus.classList.add("down");
			$wsStatus.classList.remove("live");
			setTimeout(connectWs, 3000);
		};
		ws.onerror = () => ws.close();
	} catch (e) {
		setTimeout(connectWs, 3000);
	}
}

// New run dialog wiring
document.getElementById("new-run-btn").addEventListener("click", () => {
	document.getElementById("new-run-dialog").showModal();
});
document.getElementById("new-run-form").addEventListener("submit", async (e) => {
	e.preventDefault();
	const fd = new FormData(e.target);
	const body = { niche: fd.get("niche"), mode: fd.get("mode") };
	const r = await fetch(`${API}/runs`, {
		method: "POST",
		headers: { "content-type": "application/json" },
		body: JSON.stringify(body),
	});
	const j = await r.json().catch(() => ({}));
	document.getElementById("new-run-dialog").close();
	appendEvent({ stage: "orchestrator", event: "spawned", payload: JSON.stringify(j) });
	setTimeout(refresh, 800);
});

refresh();
setInterval(refresh, 10000);
connectWs();
