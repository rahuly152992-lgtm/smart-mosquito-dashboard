/**
 * app.js
 * ------
 * Next-Gen IoT Command Center Controller for
 * "Smart Mosquito Breeding Detection System" (ESP32).
 */

class MosquitoApp {
  constructor() {
    this.currentScreen = "screen-home";
    this.user = {
      name: "Dr. Alok Verma",
      email: "alok.verma@health.gov.in",
      role: "Field Officer",
      isLoggedIn: true
    };
    this.latestRecord = null;
    this.deviceState = null;
    this.systemStats = null;
    this.activeAlerts = [];
    this.selectedAlert = null;
    this.pollingTimer = null;
    this.activeRiskAlarmPlayed = false;
  }

  init() {
    this._bindEvents();
    this._initTheme();
    this._initChecklistState();

    // Start with Executive Command Dashboard immediately
    this.showScreen("screen-home");
    this.startLivePolling();
    this.initDashboardChartsAndFeeds();
  }

  // --------------------------------------------------------------------------
  // Navigation & Screen Router
  // --------------------------------------------------------------------------
  showScreen(screenId) {
    this.currentScreen = screenId;

    // Update screen views
    document.querySelectorAll(".screen-view").forEach(el => {
      el.classList.remove("active");
    });
    const target = document.getElementById(screenId);
    if (target) {
      target.classList.add("active");
      target.scrollTop = 0;
    }

    // Update Sidebar Navigation Active Item
    document.querySelectorAll(".sidebar-nav .nav-item").forEach(item => {
      item.classList.remove("active");
      if (item.dataset.screen === screenId) {
        item.classList.add("active");
      }
    });

    // Update Mobile Bottom Nav Active Tab
    document.querySelectorAll(".app-bottom-nav .nav-tab-item").forEach(tab => {
      tab.classList.remove("active");
      if (tab.dataset.screen === screenId) {
        tab.classList.add("active");
      }
    });

    // Update Top Header Page Title
    const titles = {
      "screen-home": "Executive Command Dashboard",
      "screen-monitor": "Live Telemetry & Diagnostics",
      "screen-alerts": "Incident Alerts & Dispatch",
      "screen-history": "Historical Trends & Analytics",
      "screen-device": "ESP32 Hardware Diagnostics",
      "screen-tips": "Larvicide & Field Prevention",
      "screen-profile": "Officer Settings & System Config"
    };
    const titleEl = document.getElementById("page-title");
    if (titleEl && titles[screenId]) {
      titleEl.textContent = titles[screenId];
    }

    // Play click sound & haptic vibration
    if (window.soundFx) window.soundFx.playClick();
    if (navigator.vibrate) {
      try { navigator.vibrate(10); } catch(e) {}
    }

    // Close mobile drawer if open
    if (window.innerWidth <= 900) {
      const sidebar = document.getElementById("app-sidebar");
      const overlay = document.getElementById("sidebar-overlay");
      if (sidebar) sidebar.classList.remove("open");
      if (overlay) overlay.classList.remove("active");
    }

    // Screen-specific on-demand renders
    if (screenId === "screen-home") {
      this.refreshData();
    } else if (screenId === "screen-monitor") {
      this.renderMonitorScreen();
    } else if (screenId === "screen-alerts") {
      this.renderAlertsScreen();
    } else if (screenId === "screen-history") {
      this.renderHistoryScreen();
    } else if (screenId === "screen-device") {
      this.renderDeviceScreen();
    } else if (screenId === "screen-profile") {
      this.renderProfileScreen();
    }
  }

  // --------------------------------------------------------------------------
  // Data Polling & Synchronization
  // --------------------------------------------------------------------------
  startLivePolling() {
    if (this.pollingTimer) clearInterval(this.pollingTimer);
    this.refreshData();
    this.pollingTimer = setInterval(() => this.refreshData(), 4000);
  }

  async initDashboardChartsAndFeeds() {
    try {
      const records = await API.getRecords("all", "all", 20);
      if (window.telemetryCharts && records && records.length) {
        window.telemetryCharts.initLiveTelemetryChart("liveTelemetryCanvas", records);
      }
      this.renderRecentTable(records);
      this.renderAlertsScreen("all");
    } catch (e) {
      console.warn("Initial dashboard chart load:", e);
    }
  }

  async refreshData() {
    try {
      const data = await API.getLatest();
      if (!data) return;

      this.latestRecord = data.record;
      this.deviceState = data.device;
      this.systemStats = data.stats;

      this._updateUIHeaderAndBadges();
      this._updateHomeScreen();

      // Live updates to charts
      if (window.telemetryCharts && this.latestRecord) {
        window.telemetryCharts.updateLiveTelemetry(this.latestRecord);
      }

      // Live updates to secondary screens if open
      if (this.currentScreen === "screen-monitor") {
        this._updateMonitorGauges();
      } else if (this.currentScreen === "screen-device") {
        this._updateDeviceCard();
      }
    } catch (e) {
      console.warn("Polling update failed:", e);
    }
  }

  _updateUIHeaderAndBadges() {
    const activeCount = this.systemStats?.active_alerts || 0;
    
    // Header notification bell badge
    const headerBadge = document.getElementById("header-alert-badge");
    if (headerBadge) {
      headerBadge.textContent = activeCount;
      headerBadge.style.display = activeCount > 0 ? "flex" : "none";
    }

    // Sidebar & Bottom Navigation Alerts Badge
    const navBadge = document.getElementById("nav-alerts-badge");
    if (navBadge) {
      navBadge.textContent = activeCount;
      navBadge.style.display = activeCount > 0 ? "inline-block" : "none";
    }
  }

  // --------------------------------------------------------------------------
  // Executive Command Dashboard Rendering (_updateHomeScreen)
  // --------------------------------------------------------------------------
  _updateHomeScreen() {
    const rec = this.latestRecord || {
      WaterLevel: 78,
      Temperature: 29,
      Humidity: 76,
      ImageRiskScore: 88,
      RiskScore: 84,
      RiskLabel: "danger",
      Timestamp: new Date().toISOString()
    };
    const dev = this.deviceState || {};
    const stats = this.systemStats || {};

    // 1. Device connection badge in sidebar & header
    const devDot = document.getElementById("home-device-dot");
    const devTitle = document.getElementById("home-device-name");
    const devSync = document.getElementById("home-device-sync");
    const devRssi = document.getElementById("sidebar-rssi");

    if (devDot) {
      devDot.className = `status-dot ${dev.status === "offline" ? "danger" : ""}`;
    }
    if (devTitle) devTitle.textContent = dev.device_name || "ESP32 Node #1";
    if (devSync) devSync.textContent = dev.status === "connected" ? "Telemetry Online" : "Connecting...";
    if (devRssi && dev.rssi) devRssi.textContent = `${dev.rssi} dBm`;

    // 2. Risk Status Badges & Verdict Ring
    const statusBadge = document.getElementById("home-status-badge");
    const statusHeadline = document.getElementById("home-status-headline");
    const statusDesc = document.getElementById("home-status-desc");
    const statusTime = document.getElementById("home-status-time");
    const verdictScore = document.getElementById("verdict-score-num");
    const verdictRing = document.getElementById("verdict-gauge-ring");

    const risk = rec.RiskLabel || "safe";
    const score = rec.RiskScore != null ? rec.RiskScore : (risk === "danger" ? 86 : (risk === "caution" ? 54 : 18));

    if (verdictScore) verdictScore.textContent = score;

    if (verdictRing && verdictRing.parentElement) {
      const ringColor = risk === "danger" ? "var(--danger)" : (risk === "caution" ? "var(--caution)" : "var(--safe)");
      verdictRing.parentElement.style.background = `conic-gradient(${ringColor} 0%, ${ringColor} ${score}%, rgba(255, 255, 255, 0.08) ${score}%)`;
      if (verdictScore) verdictScore.style.color = ringColor;
    }

    if (statusBadge) {
      statusBadge.className = `header-risk-pill ${risk}`;
      statusBadge.textContent = risk === "danger" ? "HIGH RISK" : (risk === "caution" ? "CAUTION" : "SAFE");
    }

    if (statusHeadline) {
      statusHeadline.textContent = risk === "danger"
        ? "CRITICAL BREEDING RISK DETECTED"
        : (risk === "caution" ? "CAUTION: CONDITIONS FAVORABLE" : "LOW RISK: ENVIRONMENT SAFE");
    }

    if (statusDesc) {
      statusDesc.textContent = risk === "danger"
        ? "Stagnant water level and warm ambient temperature are in prime breeding zone. Automated drainage pump activated."
        : (risk === "caution" ? "Water level approaching warning threshold. Continuous monitoring active." : "Environmental parameters are outside mosquito egg incubation thresholds.");
    }

    if (statusTime) {
      const timeStr = new Date(rec.Timestamp || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      statusTime.textContent = `Updated: ${timeStr}`;
    }

    // 3. Emergency High-Risk Banner & Alarm
    const emergencyBanner = document.getElementById("home-emergency-banner");
    if (emergencyBanner) {
      if (risk === "danger") {
        emergencyBanner.style.display = "block";
        if (!this.activeRiskAlarmPlayed && window.soundFx) {
          window.soundFx.playAlarm();
          this.activeRiskAlarmPlayed = true;
        }
      } else {
        emergencyBanner.style.display = "none";
        this.activeRiskAlarmPlayed = false;
      }
    }

    // 4. Primary KPI Metric Cards
    // Metric 1: Water Level
    const wlVal = document.getElementById("home-val-water");
    const wlFill = document.getElementById("home-fill-water");
    const wlStatus = document.getElementById("home-status-water");
    const wlDepth = document.getElementById("home-water-depth");
    const waterLvl = rec.WaterLevel ?? 78;

    if (wlVal) wlVal.textContent = `${waterLvl}%`;
    if (wlFill) {
      wlFill.style.width = `${Math.min(100, waterLvl)}%`;
      wlFill.style.background = waterLvl >= 70 ? "var(--danger)" : (waterLvl >= 50 ? "var(--caution)" : "var(--primary)");
    }
    if (wlStatus) {
      wlStatus.className = `kpi-status-pill ${waterLvl >= 70 ? 'danger' : (waterLvl >= 50 ? 'caution' : '')}`;
      wlStatus.textContent = waterLvl >= 70 ? "Stagnant Alert" : (waterLvl >= 50 ? "Moderate" : "Safe");
    }
    if (wlDepth) {
      wlDepth.textContent = `Depth: ${(waterLvl * 0.25).toFixed(1)} cm`;
    }

    // Metric 2: Temperature
    const tempVal = document.getElementById("home-val-temp");
    const tempFill = document.getElementById("home-fill-temp");
    const tempStatus = document.getElementById("home-status-temp");
    const tempF = document.getElementById("home-temp-f");
    const temp = rec.Temperature ?? 29;

    if (tempVal) tempVal.textContent = `${temp}°C`;
    if (tempFill) {
      const tempPercent = Math.min(100, Math.max(0, ((temp - 15) / 25) * 100));
      tempFill.style.width = `${tempPercent}%`;
      tempFill.style.background = (temp >= 24 && temp <= 33) ? "var(--danger)" : "var(--safe)";
    }
    if (tempStatus) {
      const isBreeding = temp >= 24 && temp <= 33;
      tempStatus.className = `kpi-status-pill ${isBreeding ? 'danger' : ''}`;
      tempStatus.textContent = isBreeding ? "Prime Breeding" : "Safe Zone";
    }
    if (tempF) {
      tempF.textContent = `${((temp * 9/5) + 32).toFixed(1)}°F`;
    }

    // Metric 3: Relative Humidity
    const humVal = document.getElementById("home-val-humidity");
    const humFill = document.getElementById("home-fill-humidity");
    const humStatus = document.getElementById("home-status-humidity");
    const humidity = rec.Humidity ?? 76;

    if (humVal) humVal.textContent = `${humidity}%`;
    if (humFill) {
      humFill.style.width = `${Math.min(100, humidity)}%`;
      humFill.style.background = humidity >= 65 ? "var(--caution)" : "var(--safe)";
    }
    if (humStatus) {
      humStatus.className = `kpi-status-pill ${humidity >= 65 ? 'caution' : ''}`;
      humStatus.textContent = humidity >= 65 ? "High Saturation" : "Optimal";
    }

    // Metric 4: AI Optical / Larvae Index
    const imgVal = document.getElementById("home-val-image");
    const imgFill = document.getElementById("home-fill-image");
    const imgStatus = document.getElementById("home-status-image");
    const larvaeScore = rec.ImageRiskScore ?? (risk === "danger" ? 88 : 12);

    if (imgVal) imgVal.textContent = `${larvaeScore}%`;
    if (imgFill) {
      imgFill.style.width = `${Math.min(100, larvaeScore)}%`;
      imgFill.style.background = larvaeScore >= 70 ? "var(--danger)" : (larvaeScore >= 40 ? "var(--caution)" : "var(--safe)");
    }
    if (imgStatus) {
      imgStatus.className = `kpi-status-pill ${larvaeScore >= 70 ? 'danger' : (larvaeScore >= 40 ? 'caution' : '')}`;
      imgStatus.textContent = larvaeScore >= 70 ? "Larvae Pos" : "Clear";
    }

    // 5. Actuator Pump State
    const pumpDot = document.getElementById("pump-state-dot");
    const pumpText = document.getElementById("pump-state-text");
    const pumpSwitch = document.getElementById("pump-manual-switch");
    const isPumpOn = dev.pump_state === "ON" || (risk === "danger" && dev.pump_mode === "auto");

    if (pumpDot) pumpDot.className = `pump-state-dot ${isPumpOn ? 'active' : ''}`;
    if (pumpText) pumpText.textContent = `Pump ${isPumpOn ? 'RUNNING (Draining)' : 'STANDBY (Off)'}`;
    if (pumpSwitch && !pumpSwitch.matches(':focus')) {
      pumpSwitch.checked = isPumpOn;
    }

    // 6. Quick Alert Counts
    const statActive = document.getElementById("home-stat-active");
    const statResolved = document.getElementById("home-stat-resolved");
    if (statActive) statActive.textContent = `${stats.active_alerts || 0} Active`;
    if (statResolved) statResolved.textContent = `${stats.resolved_alerts || 0} Resolved`;
  }

  // --------------------------------------------------------------------------
  // Recent Telemetry Table
  // --------------------------------------------------------------------------
  async renderRecentTable(records) {
    const tbody = document.getElementById("history-table-body");
    if (!tbody) return;

    if (!records || !records.length) {
      tbody.innerHTML = `<tr><td colspan="6" style="text-align:center; padding:20px; color:var(--text-muted);">No records logged yet.</td></tr>`;
      return;
    }

    tbody.innerHTML = records.slice(0, 8).map(r => {
      const timeStr = new Date(r.Timestamp || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
      const risk = r.RiskLabel || "safe";
      return `
        <tr>
          <td>${timeStr}</td>
          <td><strong>${r.WaterLevel ?? '--'}%</strong></td>
          <td>${r.Temperature ?? '--'}°C</td>
          <td>${r.Humidity ?? '--'}%</td>
          <td><span class="risk-badge-pill ${risk}">${risk.toUpperCase()}</span></td>
          <td>${r.Latitude ? `${r.Latitude.toFixed(4)}, ${r.Longitude.toFixed(4)}` : '28.6139, 77.2090'}</td>
        </tr>
      `;
    }).join("");
  }

  // --------------------------------------------------------------------------
  // Monitor Channels Screen
  // --------------------------------------------------------------------------
  async renderMonitorScreen() {
    this._updateMonitorGauges();
    const records = await API.getRecords("all", "all", 20);
    if (window.telemetryCharts) {
      window.telemetryCharts.initLiveTelemetryChart("liveTelemetryCanvas", records);
    }
  }

  _updateMonitorGauges() {
    const rec = this.latestRecord || {};
    const dev = this.deviceState || {};

    const monWl = document.getElementById("mon-val-water");
    const monTemp = document.getElementById("mon-val-temp");
    const monHum = document.getElementById("mon-val-hum");
    const monImg = document.getElementById("mon-val-img");
    const monPump = document.getElementById("mon-val-pump");
    const monPumpText = document.getElementById("mon-pump-text");
    const monSync = document.getElementById("mon-val-sync");

    if (monWl) monWl.textContent = `${rec.WaterLevel ?? "--"}%`;
    if (monTemp) monTemp.textContent = `${rec.Temperature ?? "--"}°C`;
    if (monHum) monHum.textContent = `${rec.Humidity ?? "--"}%`;
    if (monImg) monImg.textContent = `${rec.ImageRiskScore ?? "--"}% Larvae`;
    if (monPump) monPump.textContent = dev.pump_state === "ON" ? "Active" : "Standby";
    if (monPumpText) monPumpText.textContent = dev.pump_state === "ON" ? "RUNNING (ON)" : "STANDBY (OFF)";
    if (monSync) monSync.textContent = `Sync: ${new Date(rec.Timestamp || Date.now()).toLocaleTimeString()}`;
  }

  // --------------------------------------------------------------------------
  // Alerts Feed Screen & Incident Handling
  // --------------------------------------------------------------------------
  async renderAlertsScreen(filterStatus = "all") {
    const container = document.getElementById("alerts-list-container");
    const fullContainer = document.getElementById("alerts-full-list");

    const alerts = await API.getAlerts(filterStatus);
    this.activeAlerts = alerts;

    const htmlContent = !alerts.length
      ? `<div style="text-align:center; padding:24px 12px; color:var(--text-muted);">
           <span style="font-size:1.5rem;">🟢</span>
           <p style="margin-top:6px; font-weight:600;">No active incidents recorded.</p>
         </div>`
      : alerts.map(a => {
          const isDanger = a.risk_level === "danger";
          const isCaution = a.risk_level === "caution";
          const isResolved = a.status === "resolved";
          const badgeClass = isResolved ? "safe" : (isDanger ? "danger" : "caution");
          const timeAgo = this._timeAgo(a.created_at || a.last_updated);

          return `
            <div class="alert-item-card ${isDanger ? 'danger' : (isCaution ? 'caution' : 'safe')}">
              <div class="alert-item-header">
                <strong style="font-size:0.86rem; color:var(--text-main);">${a.title || 'Breeding Risk Warning'}</strong>
                <span class="risk-badge-pill ${badgeClass}">${isResolved ? 'RESOLVED' : (isDanger ? 'HIGH RISK' : 'CAUTION')}</span>
              </div>
              <div class="alert-item-meta">
                <span>📍 ${a.location || 'Sector 4 Drain'}</span>
                <span>⏱ ${timeAgo}</span>
              </div>
              <div class="alert-telemetry-pills">
                <span>💧 ${a.water_level}% Water</span>
                <span>🌡️ ${a.temperature}°C</span>
                <span>💨 ${a.humidity}% RH</span>
              </div>
              <div class="alert-item-actions">
                <button class="btn-secondary" onclick="app.openAlertDetails('${a.alert_id}')">Details</button>
                ${!isResolved ? `
                  <button class="btn-resolve" onclick="app.quickResolveAlert('${a.alert_id}')">✓ Resolve</button>
                ` : `
                  <button class="btn-secondary" style="color:var(--safe); border-color:var(--safe);" disabled>✓ Cleaned</button>
                `}
              </div>
            </div>
          `;
        }).join("");

    if (container) container.innerHTML = htmlContent;
    if (fullContainer) fullContainer.innerHTML = htmlContent;
  }

  _timeAgo(timestamp) {
    if (!timestamp) return "Just now";
    const sec = Math.floor((Date.now() - new Date(timestamp).getTime()) / 1000);
    if (sec < 60) return "Just now";
    if (sec < 3600) return `${Math.floor(sec / 60)}m ago`;
    if (sec < 86400) return `${Math.floor(sec / 3600)}h ago`;
    return `${Math.floor(sec / 86400)}d ago`;
  }

  // --------------------------------------------------------------------------
  // Alert Details Modal & Actions
  // --------------------------------------------------------------------------
  async openAlertDetails(alertId) {
    const alert = await API.getAlertDetails(alertId);
    if (!alert) return;

    this.selectedAlert = alert;
    const modal = document.getElementById("alert-details-modal");
    if (!modal) return;

    const idEl = document.getElementById("modal-alert-id");
    const titleEl = document.getElementById("modal-alert-title");
    const timeEl = document.getElementById("modal-alert-time");
    const locEl = document.getElementById("modal-alert-loc");
    const devEl = document.getElementById("modal-alert-device");

    if (idEl) idEl.textContent = `ID: ${alert.alert_id}`;
    if (titleEl) titleEl.textContent = alert.title;
    if (timeEl) timeEl.textContent = new Date(alert.created_at || alert.last_updated).toLocaleString();
    if (locEl) locEl.textContent = alert.location || "Sector 4";
    if (devEl) devEl.textContent = alert.device_id || "ESP32-01";

    const wlEl = document.getElementById("modal-wl");
    const tempEl = document.getElementById("modal-temp");
    const humEl = document.getElementById("modal-hum");
    const imgEl = document.getElementById("modal-img");

    if (wlEl) wlEl.textContent = `${alert.water_level}%`;
    if (tempEl) tempEl.textContent = `${alert.temperature}°C`;
    if (humEl) humEl.textContent = `${alert.humidity}%`;
    if (imgEl) imgEl.textContent = `${alert.image_risk_score}%`;

    const reasonsBox = document.getElementById("modal-reasons-list");
    if (reasonsBox) {
      const reasons = alert.reasons || ["Stagnant water level exceeds breeding safety limit (>70%)."];
      reasonsBox.innerHTML = reasons.map(r => `<li style="margin-bottom:4px;">${r}</li>`).join("");
    }

    const logsBox = document.getElementById("modal-actions-history");
    if (logsBox) {
      const logs = alert.actions_log || [];
      logsBox.innerHTML = logs.length
        ? logs.map(l => `<div style="padding:4px 0; border-bottom:1px solid var(--border-subtle);"><strong style="color:var(--text-main);">${l.actor || 'Officer'}:</strong> ${l.action}</div>`).join("")
        : "No field interventions logged yet.";
    }

    modal.classList.add("active");
    if (window.soundFx) window.soundFx.playClick();
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove("active");
  }

  async quickResolveAlert(alertId) {
    const res = await API.resolveAlert(alertId, this.user.name, "Resolved via Quick Action on Command Dashboard");
    if (res && res.success) {
      this.showToast("Incident marked as Resolved!");
      this.refreshData();
      this.renderAlertsScreen();
      if (window.soundFx) window.soundFx.playSafe();
    } else {
      this.showToast("Error resolving incident");
    }
  }

  openActionReportModal() {
    this.closeModal("alert-details-modal");
    const modal = document.getElementById("report-action-modal");
    if (modal) modal.classList.add("active");
  }

  async submitActionReport() {
    if (!this.selectedAlert) return;

    const actionType = document.getElementById("action-type-select")?.value || "larvicide";
    const customNote = document.getElementById("action-custom-note")?.value || "";
    const markCleaned = document.getElementById("action-mark-cleaned")?.checked || false;
    const markResolved = document.getElementById("action-mark-resolved")?.checked || false;

    const actionText = `${actionType.toUpperCase()}: ${customNote}`;
    const res = await API.logAlertAction(this.selectedAlert.alert_id, this.user.name, actionText, markCleaned, markResolved);

    if (res && res.success) {
      this.showToast("Field intervention logged successfully!");
      this.closeModal("report-action-modal");
      this.refreshData();
      this.renderAlertsScreen();
    } else {
      this.showToast("Failed to log intervention");
    }
  }

  // --------------------------------------------------------------------------
  // History Trends & Distribution Screen
  // --------------------------------------------------------------------------
  async renderHistoryScreen() {
    const records = await API.getRecords("all", "all", 50);
    const stats = await API.getStats();

    if (window.telemetryCharts) {
      window.telemetryCharts.initHistoryTrendChart("historyTrendCanvas", records);
      window.telemetryCharts.initRiskDistChart("riskDistCanvas", stats || {});
    }
  }

  // --------------------------------------------------------------------------
  // ESP32 Hardware Diagnostics Screen
  // --------------------------------------------------------------------------
  async renderDeviceScreen() {
    this._updateDeviceCard();
  }

  _updateDeviceCard() {
    const dev = this.deviceState || {};
    const nameEl = document.getElementById("dev-screen-name");
    const idEl = document.getElementById("dev-screen-id");
    const rssiEl = document.getElementById("dev-screen-rssi");
    const battEl = document.getElementById("dev-screen-batt");
    const syncEl = document.getElementById("dev-screen-sync");

    if (nameEl) nameEl.textContent = dev.device_name || "ESP32 Mosquito Guard Node #1";
    if (idEl) idEl.textContent = dev.device_id || "ESP32-MG-01";
    if (rssiEl) rssiEl.textContent = `${dev.rssi || -64} dBm (Signal Strong)`;
    if (battEl) battEl.textContent = `${dev.battery_level || 94}% (Li-Ion 4.18V)`;
    if (syncEl) syncEl.textContent = dev.status === "connected" ? "HTTPS REST / Live SSE" : "Offline";
  }

  // --------------------------------------------------------------------------
  // Officer Profile & Settings Screen
  // --------------------------------------------------------------------------
  renderProfileScreen() {
    const nameInput = document.getElementById("prof-user-name");
    const emailInput = document.getElementById("prof-user-email");
    const roleSelect = document.getElementById("prof-role-select");
    const roleDesc = document.getElementById("prof-user-role");

    if (nameInput) nameInput.value = this.user.name;
    if (emailInput) emailInput.value = this.user.email;
    if (roleSelect) roleSelect.value = this.user.role;
    if (roleDesc) roleDesc.textContent = `Active Role: ${this.user.role} — Full administrative and field action privileges.`;
  }

  changeRole(newRole) {
    this.user.role = newRole;
    this.renderProfileScreen();
    this.showToast(`Active role switched to: ${newRole}`);
  }

  // --------------------------------------------------------------------------
  // Citizen Mosquito Spot Report
  // --------------------------------------------------------------------------
  openCitizenReportModal() {
    const modal = document.getElementById("citizen-report-modal");
    if (modal) modal.classList.add("active");
    if (window.soundFx) window.soundFx.playClick();
  }

  async submitCitizenReport() {
    const loc = document.getElementById("cit-location")?.value || "Sector 4";
    const type = document.getElementById("cit-hazard-type")?.value || "stagnant_water";
    const desc = document.getElementById("cit-desc")?.value || "Community report";

    const res = await API.logAlertAction("CITIZEN-REP-" + Date.now().toString().slice(-4), "Citizen / Field Reporter", `Spot Report: ${type} at ${loc} (${desc})`, false, false);
    this.showToast("Report transmitted to Vector Control Team!");
    this.closeModal("citizen-report-modal");
    this.renderAlertsScreen();
  }

  // --------------------------------------------------------------------------
  // Viva Simulation Trigger & Pump Controls
  // --------------------------------------------------------------------------
  async triggerScenario(scenario) {
    this.showToast(`Injecting Scenario: ${scenario.replace('_', ' ').toUpperCase()}...`);
    const res = await API.simulate(scenario);
    if (res && res.success) {
      this.showToast(`Scenario Injected! Updating telemetry...`);
      setTimeout(() => {
        this.refreshData();
        this.initDashboardChartsAndFeeds();
      }, 500);
    } else {
      this.showToast("Failed to inject simulation");
    }
  }

  triggerPumpFromEmergency() {
    controlPumpDirect("ON");
    this.showToast("Emergency Drainage Pump Activated!");
  }

  // --------------------------------------------------------------------------
  // Prevention Checklist State
  // --------------------------------------------------------------------------
  _initChecklistState() {
    this.checklistState = JSON.parse(localStorage.getItem("mosquito_checklist") || "[false,false,false,false,false,false]");
    this._updateChecklistUI();
  }

  toggleChecklist(index) {
    this.checklistState[index] = !this.checklistState[index];
    localStorage.setItem("mosquito_checklist", JSON.stringify(this.checklistState));
    this._updateChecklistUI();
    if (window.soundFx) window.soundFx.playClick();
  }

  _updateChecklistUI() {
    const completed = this.checklistState.filter(Boolean).length;
    const fill = document.getElementById("checklist-progress-fill");
    const text = document.getElementById("checklist-progress-text");

    if (fill) fill.style.width = `${(completed / 6) * 100}%`;
    if (text) text.textContent = `${completed} / 6 Completed`;

    const inputs = document.querySelectorAll(".checklist-items input[type='checkbox']");
    inputs.forEach((inp, idx) => {
      inp.checked = !!this.checklistState[idx];
    });
  }

  // --------------------------------------------------------------------------
  // Theme Toggle (Dark / Light)
  // --------------------------------------------------------------------------
  _initTheme() {
    const saved = localStorage.getItem("mosquito_theme") || "dark";
    const toggle = document.getElementById("theme-toggle-chk");
    if (saved === "light") {
      document.body.classList.remove("dark-mode");
      if (toggle) toggle.checked = false;
    } else {
      document.body.classList.add("dark-mode");
      if (toggle) toggle.checked = true;
    }
  }

  toggleTheme() {
    const isDark = document.body.classList.toggle("dark-mode");
    localStorage.setItem("mosquito_theme", isDark ? "dark" : "light");
    if (window.soundFx) window.soundFx.playClick();
    if (window.telemetryCharts) {
      this.renderMonitorScreen();
    }
  }

  // --------------------------------------------------------------------------
  // Events Binding
  // --------------------------------------------------------------------------
  _bindEvents() {
    // Filter chips for alerts screen
    document.querySelectorAll(".filter-chip").forEach(chip => {
      chip.addEventListener("click", () => {
        document.querySelectorAll(".filter-chip").forEach(c => c.classList.remove("active"));
        chip.classList.add("active");
        const status = chip.dataset.status || "all";
        this.renderAlertsScreen(status);
      });
    });
  }

  // --------------------------------------------------------------------------
  // Toast Notification Display
  // --------------------------------------------------------------------------
  showToast(message) {
    const container = document.getElementById("toast-container");
    if (!container) return;

    const toast = document.createElement("div");
    toast.className = "toast-message";
    toast.innerHTML = `<span>⚡</span> <span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = "0";
      toast.style.transform = "translateY(8px)";
      toast.style.transition = "all 0.3s ease";
      setTimeout(() => toast.remove(), 300);
    }, 3200);
  }
}

// Global App Initialization
document.addEventListener("DOMContentLoaded", () => {
  window.app = new MosquitoApp();
  window.app.init();
});
