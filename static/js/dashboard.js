/**
 * dashboard.js
 * ------------
 * Polls the Flask backend (Section 4.6) every few seconds and updates
 * the live cards, status badge, and the recent-alerts table. No page
 * reload is required, matching the behaviour described in the report.
 */

const POLL_INTERVAL_MS = 5000;
const riskFilterEl = document.getElementById("riskFilter");

function setStatus(label) {
  const badge = document.getElementById("statusBadge");
  badge.textContent = label.toUpperCase();
  badge.className = `status-badge ${label}`;
}

function fmtTime(isoString) {
  if (!isoString) return "--";
  const d = new Date(isoString);
  return isNaN(d) ? isoString : d.toLocaleString();
}

async function refreshLatest() {
  try {
    const res = await fetch("/api/latest");
    const data = await res.json();
    if (!data || !data.RecordID) return;

    document.getElementById("waterLevel").textContent = data.WaterLevel ?? "--";
    document.getElementById("temperature").textContent = data.Temperature ?? "--";
    document.getElementById("humidity").textContent = data.Humidity ?? "--";
    setStatus(data.RiskLabel || "safe");
    document.getElementById("lastUpdated").textContent = `Updated: ${fmtTime(data.Timestamp)}`;
  } catch (err) {
    console.error("Failed to fetch latest record:", err);
  }
}

async function refreshTable() {
  const risk = riskFilterEl.value;
  try {
    const res = await fetch(`/api/records?risk=${encodeURIComponent(risk)}&limit=50`);
    const records = await res.json();
    const tbody = document.getElementById("recordsBody");

    if (!records.length) {
      tbody.innerHTML = '<tr><td colspan="6" class="empty-row">No records yet.</td></tr>';
      return;
    }

    tbody.innerHTML = records.map(r => `
      <tr>
        <td>${fmtTime(r.Timestamp)}</td>
        <td>${r.WaterLevel ?? "--"}</td>
        <td>${r.Temperature ?? "--"}</td>
        <td>${r.Humidity ?? "--"}</td>
        <td><span class="risk-pill ${r.RiskLabel}">${r.RiskLabel}</span></td>
        <td>${r.Latitude != null ? `${r.Latitude}, ${r.Longitude}` : "--"}</td>
      </tr>
    `).join("");
  } catch (err) {
    console.error("Failed to fetch records:", err);
  }
}

function refreshAll() {
  refreshLatest();
  refreshTable();
}

riskFilterEl.addEventListener("change", refreshTable);

refreshAll();
setInterval(refreshAll, POLL_INTERVAL_MS);
