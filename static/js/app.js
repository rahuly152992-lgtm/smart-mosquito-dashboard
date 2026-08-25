/**
 * app.js
 * ------
 * Main Single Page Application (SPA) Controller for
 * "Smart Mosquito Breeding Detection System".
 */

class MosquitoApp {
  constructor() {
    this.currentScreen = "screen-splash";
    this.user = {
      name: "Dr. Alok Verma",
      email: "alok.verma@health.gov.in",
      role: "Field Officer", // "Field Officer" | "Administrator" | "Student Researcher"
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
    this._checkAuthAndStart();
    this._initChecklistState();
  }

  // --------------------------------------------------------------------------
  // Navigation & Screen Router
  // --------------------------------------------------------------------------
  showScreen(screenId) {
    if (!this.user.isLoggedIn && screenId !== "screen-login" && screenId !== "screen-splash") {
      screenId = "screen-login";
    }

    const previousScreen = this.currentScreen;
    this.currentScreen = screenId;

    // Update screen elements
    document.querySelectorAll(".screen-view").forEach(el => {
      el.classList.remove("active");
    });
    const target = document.getElementById(screenId);
    if (target) {
      target.classList.add("active");
      target.scrollTop = 0;
    }

    // Update Bottom Navigation Active Tab
    document.querySelectorAll(".nav-tab-item").forEach(tab => {
      tab.classList.remove("active");
      if (tab.dataset.screen === screenId) {
        tab.classList.add("active");
      }
    });

    // Handle Header & Bottom Nav Visibility
    const isSplash = screenId === "screen-splash";
    const isLogin = screenId === "screen-login";
    const bottomNav = document.getElementById("main-bottom-nav");
    const appHeader = document.getElementById("main-app-header");

    if (bottomNav) bottomNav.style.display = (isSplash || isLogin) ? "none" : "flex";
    if (appHeader) appHeader.style.display = (isSplash || isLogin) ? "none" : "flex";

    // Play click sound
    if (!isSplash && window.soundFx) {
      window.soundFx.playClick();
    }

    // On-demand screen re-renders
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

  _checkAuthAndStart() {
    // Splash screen animation timer -> transitions after 1.8 seconds
    setTimeout(() => {
      const splash = document.getElementById("screen-splash");
      if (splash && this.currentScreen === "screen-splash") {
        if (this.user.isLoggedIn) {
          this.showScreen("screen-home");
          this.startLivePolling();
        } else {
          this.showScreen("screen-login");
        }
      }
    }, 1800);
  }

  // --------------------------------------------------------------------------
  // Data Polling & Synchronization
  // --------------------------------------------------------------------------
  startLivePolling() {
    if (this.pollingTimer) clearInterval(this.pollingTimer);
    this.refreshData();
    this.pollingTimer = setInterval(() => this.refreshData(), 4000);
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

      // Live screen updates
      if (this.currentScreen === "screen-monitor") {
        this._updateMonitorGauges();
        if (window.telemetryCharts) {
          window.telemetryCharts.updateLiveTelemetry(this.latestRecord);
        }
      } else if (this.currentScreen === "screen-device") {
        this._updateDeviceCard();
      }
    } catch (e) {
      console.warn("Polling update failed:", e);
    }
  }

  _updateUIHeaderAndBadges() {
    const activeCount = this.systemStats?.active_alerts || 0;
    
    // Header notification badge
    const headerBadge = document.getElementById("header-alert-badge");
    if (headerBadge) {
      headerBadge.textContent = activeCount;
      headerBadge.style.display = activeCount > 0 ? "flex" : "none";
    }

    // Bottom Navigation Alerts Badge
    const navBadge = document.getElementById("nav-alerts-badge");
    if (navBadge) {
      navBadge.textContent = activeCount;
      navBadge.style.display = activeCount > 0 ? "flex" : "none";
    }
  }

  // --------------------------------------------------------------------------
  // 3. Home Dashboard Screen Rendering
  // --------------------------------------------------------------------------
  _updateHomeScreen() {
    const rec = this.latestRecord || {
      WaterLevel: 78,
      Temperature: 29,
      Humidity: 76,
      ImageRiskScore: 88,
      RiskLabel: "danger",
      Timestamp: new Date().toISOString()
    };
    const dev = this.deviceState || {};
    const stats = this.systemStats || {};

    // 1. Device connection banner
    const devDot = document.getElementById("home-device-dot");
    const devTitle = document.getElementById("home-device-name");
    const devSub = document.getElementById("home-device-sync");
    if (devDot) {
      devDot.className = `device-dot ${dev.status === "connected" ? "" : "offline"}`;
    }
    if (devTitle) devTitle.textContent = dev.device_name || "ESP32 Mosquito Guard #1";
    if (devSub) devSub.textContent = `Node: ${dev.device_id || "ESP32-01"} • Battery: ${dev.battery_level || 94}% • ${dev.location || "Sector 4"}`;

    // 2. System Status Card
    const statusCard = document.getElementById("home-system-status-card");
    const statusBadge = document.getElementById("home-status-badge");
    const statusHeadline = document.getElementById("home-status-headline");
    const statusDesc = document.getElementById("home-status-desc");
    const statusTime = document.getElementById("home-status-time");

    const risk = rec.RiskLabel || "safe";
    if (statusCard) {
      statusCard.className = `system-status-card ${risk}`;
    }

    if (risk === "danger") {
      if (statusBadge) statusBadge.innerHTML = `<span>🔴</span> High Breeding Risk`;
      if (statusHeadline) statusHeadline.textContent = "🔴 BREEDING RISK DETECTED";
      if (statusDesc) statusDesc.textContent = "Stagnant water level & favorable breeding temperature detected. Immediate action required.";
    } else if (risk === "caution") {
      if (statusBadge) statusBadge.innerHTML = `<span>🟡</span> Caution Warning`;
      if (statusHeadline) statusHeadline.textContent = "🟡 CAUTION – CHECK WATER CONDITIONS";
      if (statusDesc) statusDesc.textContent = "Water conditions approaching threshold. Monitor drainage and inspect containers.";
    } else {
      if (statusBadge) statusBadge.innerHTML = `<span>🟢</span> Area Safe`;
      if (statusHeadline) statusHeadline.textContent = "🟢 SAFE AREA";
      if (statusDesc) statusDesc.textContent = "Environmental readings normal. No stagnant water breeding risk found.";
    }

    if (statusTime) {
      const timeStr = new Date(rec.Timestamp || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      statusTime.textContent = `Updated: ${timeStr}`;
    }

    // 3. Live Sensor Cards
    // Water
    const wlVal = document.getElementById("home-val-water");
    const wlFill = document.getElementById("home-fill-water");
    const wlStatus = document.getElementById("home-status-water");
    if (wlVal) wlVal.textContent = rec.WaterLevel ?? "--";
    if (wlFill) {
      wlFill.style.width = `${Math.min(100, rec.WaterLevel || 0)}%`;
      wlFill.style.background = rec.WaterLevel >= 70 ? "var(--danger)" : (rec.WaterLevel >= 50 ? "var(--caution)" : "var(--primary)");
    }
    if (wlStatus) {
      wlStatus.innerHTML = rec.WaterLevel >= 70 ? "<span style='color:var(--danger)'>⚠️ Overflow Risk</span>" : "<span style='color:var(--safe)'>✓ Normal Level</span>";
    }

    // Temperature
    const tempVal = document.getElementById("home-val-temp");
    const tempFill = document.getElementById("home-fill-temp");
    const tempStatus = document.getElementById("home-status-temp");
    if (tempVal) tempVal.textContent = rec.Temperature ?? "--";
    if (tempFill) {
      const tempPercent = Math.min(100, Math.max(0, ((rec.Temperature - 15) / 25) * 100));
      tempFill.style.width = `${tempPercent}%`;
      tempFill.style.background = (rec.Temperature >= 20 && rec.Temperature <= 32) ? "var(--caution)" : "var(--safe)";
    }
    if (tempStatus) {
      tempStatus.innerHTML = (rec.Temperature >= 20 && rec.Temperature <= 32) ? "<span style='color:var(--caution)'>⚠️ Optimal Breeding Range</span>" : "<span style='color:var(--safe)'>✓ Safe Climate</span>";
    }

    // Humidity
    const humVal = document.getElementById("home-val-humidity");
    const humFill = document.getElementById("home-fill-humidity");
    const humStatus = document.getElementById("home-status-humidity");
    if (humVal) humVal.textContent = rec.Humidity ?? "--";
    if (humFill) {
      humFill.style.width = `${Math.min(100, rec.Humidity || 0)}%`;
      humFill.style.background = rec.Humidity >= 60 ? "var(--caution)" : "var(--safe)";
    }
    if (humStatus) {
      humStatus.innerHTML = rec.Humidity >= 60 ? "<span style='color:var(--caution)'>⚠️ High Moisture</span>" : "<span style='color:var(--safe)'>✓ Dry Ambient</span>";
    }

    // Image Risk Score
    const imgVal = document.getElementById("home-val-image");
    const imgFill = document.getElementById("home-fill-image");
    const imgStatus = document.getElementById("home-status-image");
    if (imgVal) imgVal.textContent = rec.ImageRiskScore ?? "--";
    if (imgFill) {
      imgFill.style.width = `${Math.min(100, rec.ImageRiskScore || 0)}%`;
      imgFill.style.background = rec.ImageRiskScore >= 65 ? "var(--danger)" : (rec.ImageRiskScore >= 40 ? "var(--caution)" : "var(--safe)");
    }
    if (imgStatus) {
      imgStatus.innerHTML = rec.ImageRiskScore >= 65 ? "<span style='color:var(--danger)'>⚠️ Larvae Detected (AI)</span>" : "<span style='color:var(--safe)'>✓ Clean Water Surface</span>";
    }

    // 4. Quick stats summary row
    const statToday = document.getElementById("home-stat-today");
    const statActive = document.getElementById("home-stat-active");
    const statResolved = document.getElementById("home-stat-resolved");
    if (statToday) statToday.textContent = stats.today_alerts ?? "2";
    if (statActive) statActive.textContent = stats.active_alerts ?? "2";
    if (statResolved) statResolved.textContent = stats.resolved_alerts ?? "2";

    // 5. Emergency Banner on Home
    const emergencyBanner = document.getElementById("home-emergency-banner");
    if (emergencyBanner) {
      emergencyBanner.style.display = (risk === "danger") ? "flex" : "none";
    }
  }

  // --------------------------------------------------------------------------
  // 4. Live Monitoring Screen Rendering
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
    const monSync = document.getElementById("mon-val-sync");

    if (monWl) monWl.textContent = `${rec.WaterLevel ?? "--"}%`;
    if (monTemp) monTemp.textContent = `${rec.Temperature ?? "--"}°C`;
    if (monHum) monHum.textContent = `${rec.Humidity ?? "--"}%`;
    if (monImg) monImg.textContent = `${rec.ImageRiskScore ?? "--"}%`;
    if (monPump) monPump.textContent = dev.pump_state === "ON" ? "RUNNING (ON)" : "STANDBY (OFF)";
    if (monSync) monSync.textContent = new Date(rec.Timestamp || Date.now()).toLocaleTimeString();
  }

  // --------------------------------------------------------------------------
  // 5. Alerts Screen Rendering
  // --------------------------------------------------------------------------
  async renderAlertsScreen(filterStatus = "all") {
    const container = document.getElementById("alerts-list-container");
    if (!container) return;

    container.innerHTML = `<div style="text-align:center; padding:30px; color:var(--text-muted);">Loading alerts...</div>`;

    const alerts = await API.getAlerts(filterStatus);
    this.activeAlerts = alerts;

    if (!alerts.length) {
      container.innerHTML = `
        <div style="text-align:center; padding:40px 20px; color:var(--text-muted);">
          <div style="font-size:2rem; margin-bottom:8px;">✅</div>
          <div style="font-weight:700; font-size:0.9rem; color:var(--text-main);">No alerts found</div>
          <p style="font-size:0.75rem; margin-top:4px;">No mosquito breeding risks recorded for this filter.</p>
        </div>
      `;
      return;
    }

    container.innerHTML = alerts.map(a => {
      const isDanger = a.risk_level === "danger";
      const isCaution = a.risk_level === "caution";
      const isResolved = a.status === "resolved";
      const badgeClass = isResolved ? "resolved" : (isDanger ? "danger" : (isCaution ? "caution" : "safe"));
      const timeAgo = this._timeAgo(a.created_at || a.last_updated);

      return `
        <div class="alert-card-item ${isDanger ? 'danger' : (isCaution ? 'caution' : '')}">
          <div class="alert-item-header">
            <div class="alert-id-tag">${a.alert_id}</div>
            <span class="risk-badge-pill ${badgeClass}">${isResolved ? 'RESOLVED' : (isDanger ? 'HIGH RISK' : 'CAUTION')}</span>
          </div>

          <div style="font-size:0.86rem; font-weight:700; color:var(--text-main);">${a.title}</div>
          <div class="alert-item-meta">
            <span>📍 ${a.location || 'Sector 4'}</span> • <span>🕒 ${timeAgo}</span>
          </div>

          <div class="alert-telemetry-pills">
            <span>💧 ${a.water_level}%</span>
            <span>🌡️ ${a.temperature}°C</span>
            <span>💨 ${a.humidity}%</span>
            <span>📷 AI: ${a.image_risk_score}%</span>
          </div>

          <div class="alert-item-actions">
            <button class="btn-secondary" onclick="app.openAlertDetails('${a.alert_id}')">View Details</button>
            ${!isResolved ? `
              <button class="btn-resolve" onclick="app.quickResolveAlert('${a.alert_id}')">✓ Mark Resolved</button>
            ` : `
              <button class="btn-secondary" style="color:var(--safe); border-color:var(--safe);" disabled>✓ Cleaned</button>
            `}
          </div>
        </div>
      `;
    }).join("");
  }

  // --------------------------------------------------------------------------
  // 6. Alert Details Modal & Actions
  // --------------------------------------------------------------------------
  async openAlertDetails(alertId) {
    const alert = await API.getAlertDetails(alertId);
    if (!alert) return;

    this.selectedAlert = alert;
    const modal = document.getElementById("alert-details-modal");
    if (!modal) return;

    document.getElementById("modal-alert-id").textContent = alert.alert_id;
    document.getElementById("modal-alert-title").textContent = alert.title;
    document.getElementById("modal-alert-time").textContent = new Date(alert.created_at || alert.last_updated).toLocaleString();
    document.getElementById("modal-alert-loc").textContent = alert.location || "Sector 4";
    document.getElementById("modal-alert-device").textContent = alert.device_id || "ESP32-01";

    document.getElementById("modal-wl").textContent = `${alert.water_level}%`;
    document.getElementById("modal-temp").textContent = `${alert.temperature}°C`;
    document.getElementById("modal-hum").textContent = `${alert.humidity}%`;
    document.getElementById("modal-img").textContent = `${alert.image_risk_score}%`;

    // Reasons breakdown
    const reasonsBox = document.getElementById("modal-reasons-list");
    if (reasonsBox) {
      const reasons = alert.reasons || ["Stagnant water level exceeds breeding safety limit (>70%)."];
      reasonsBox.innerHTML = reasons.map(r => `<li style="margin-bottom:4px;">${r}</li>`).join("");
    }

    // Action Logs
    const logsBox = document.getElementById("modal-actions-history");
    if (logsBox) {
      const logs = alert.actions_log || [];
      logsBox.innerHTML = logs.map(l => `
        <div style="font-size:0.75rem; padding:6px 0; border-bottom:1px solid var(--border-color);">
          <strong style="color:var(--text-main);">${l.actor || 'Officer'}:</strong> ${l.action}
          <div style="font-size:0.68rem; color:var(--text-muted);">${new Date(l.timestamp).toLocaleTimeString()}</div>
        </div>
      `).join("");
    }

    modal.classList.add("active");
    if (window.soundFx) window.soundFx.playClick();
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove("active");
  }

  async quickResolveAlert(alertId) {
    const actor = this.user.name || "Field Officer";
    const res = await API.resolveAlert(alertId, actor, "Inspected on site, emptied stagnant water and treated container.");
    if (res.success) {
      if (window.soundFx) window.soundFx.playSuccess();
      this.showToast(`✅ Alert ${alertId} marked as Resolved!`);
      this.renderAlertsScreen();
      this.refreshData();
    }
  }

  openReportActionModal() {
    this.closeModal("alert-details-modal");
    const modal = document.getElementById("report-action-modal");
    if (modal) modal.classList.add("active");
  }

  async submitActionReport() {
    if (!this.selectedAlert) return;
    const actionSelect = document.getElementById("action-type-select").value;
    const customNote = document.getElementById("action-custom-note").value.trim();
    const markCleaned = document.getElementById("action-mark-cleaned").checked;
    const markResolved = document.getElementById("action-mark-resolved").checked;

    const fullNote = customNote ? `${actionSelect} - ${customNote}` : actionSelect;

    const res = await API.logAlertAction(
      this.selectedAlert.alert_id,
      this.user.name,
      fullNote,
      markCleaned,
      markResolved
    );

    if (res.success) {
      if (window.soundFx) window.soundFx.playSuccess();
      this.closeModal("report-action-modal");
      this.showToast("📋 Action report logged successfully!");
      this.renderAlertsScreen();
      this.refreshData();
    }
  }

  // --------------------------------------------------------------------------
  // 7. Device Status & Hardware Diagnostics
  // --------------------------------------------------------------------------
  async renderDeviceScreen() {
    const dev = await API.getDevice();
    if (dev) this.deviceState = dev;
    this._updateDeviceCard();
  }

  _updateDeviceCard() {
    const dev = this.deviceState || {};

    const nameEl = document.getElementById("dev-screen-name");
    const idEl = document.getElementById("dev-screen-id");
    const battEl = document.getElementById("dev-screen-batt");
    const rssiEl = document.getElementById("dev-screen-rssi");
    const syncEl = document.getElementById("dev-screen-sync");

    if (nameEl) nameEl.textContent = dev.device_name || "ESP32 Mosquito Guard Node #1";
    if (idEl) idEl.textContent = `ID: ${dev.device_id || "ESP32-01"}`;
    if (battEl) battEl.textContent = `${dev.battery_level || 94}%`;
    if (rssiEl) rssiEl.textContent = `${dev.wifi_rssi || -62} dBm`;
    if (syncEl) syncEl.textContent = new Date(dev.last_sync || Date.now()).toLocaleTimeString();
  }

  testBuzzerSound() {
    if (window.soundFx) {
      window.soundFx.playBuzzerAlarm();
      this.showToast("🔔 ESP32 Hardware Buzzer Tested");
    }
  }

  // --------------------------------------------------------------------------
  // 8. History & Reports Screen
  // --------------------------------------------------------------------------
  async renderHistoryScreen(timeFilter = "all") {
    const records = await API.getRecords("all", timeFilter, 30);
    const stats = await API.getStats();

    if (window.telemetryCharts) {
      window.telemetryCharts.initHistoryTrendChart("historyTrendCanvas", records);
      window.telemetryCharts.initRiskDistChart("riskDistCanvas", stats || {});
    }

    const tableBody = document.getElementById("history-table-body");
    if (tableBody) {
      if (!records.length) {
        tableBody.innerHTML = `<tr><td colspan="5" style="text-align:center; padding:18px; color:var(--text-muted);">No records found.</td></tr>`;
        return;
      }

      tableBody.innerHTML = records.map(r => `
        <tr>
          <td style="font-size:0.75rem;">${new Date(r.Timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</td>
          <td style="font-weight:700;">${r.WaterLevel}%</td>
          <td>${r.Temperature}°C</td>
          <td>${r.Humidity}%</td>
          <td><span class="risk-badge-pill ${r.RiskLabel}">${r.RiskLabel}</span></td>
        </tr>
      `).join("");
    }
  }

  downloadReportCSV() {
    window.location.href = "/api/report/export";
    this.showToast("📥 Exporting CSV report...");
  }

  openPrintReportModal() {
    window.print();
  }

  // --------------------------------------------------------------------------
  // 9. Prevention Tips & 5-Min Checklist
  // --------------------------------------------------------------------------
  _initChecklistState() {
    const saved = localStorage.getItem("mosquito_checklist_state");
    if (saved) {
      try {
        const checkedItems = JSON.parse(saved);
        checkedItems.forEach(id => {
          const el = document.getElementById(id);
          if (el) el.checked = true;
        });
      } catch (e) {}
    }
    this._updateChecklistProgress();
  }

  toggleChecklistItem(el) {
    const items = document.querySelectorAll(".chk-item");
    const checked = Array.from(items).filter(i => i.checked).map(i => i.id);
    localStorage.setItem("mosquito_checklist_state", JSON.stringify(checked));
    this._updateChecklistProgress();
    if (window.soundFx) window.soundFx.playClick();
  }

  _updateChecklistProgress() {
    const items = document.querySelectorAll(".chk-item");
    const checked = Array.from(items).filter(i => i.checked).length;
    const progressFill = document.getElementById("checklist-progress-fill");
    const progressText = document.getElementById("checklist-progress-text");

    if (items.length && progressFill && progressText) {
      const pct = Math.round((checked / items.length) * 100);
      progressFill.style.width = `${pct}%`;
      progressText.textContent = `${pct}% Completed (${checked}/${items.length})`;
      if (pct === 100 && window.soundFx) {
        window.soundFx.playSuccess();
      }
    }
  }

  // --------------------------------------------------------------------------
  // 10. Profile & Settings
  // --------------------------------------------------------------------------
  renderProfileScreen() {
    document.getElementById("prof-user-name").textContent = this.user.name;
    document.getElementById("prof-user-email").textContent = this.user.email;
    document.getElementById("prof-user-role").textContent = this.user.role;
    document.getElementById("prof-role-select").value = this.user.role;
  }

  switchUserRole(newRole) {
    this.user.role = newRole;
    if (newRole === "Resident / Citizen") {
      this.user.name = "Rahul Sharma (Resident)";
      this.user.email = "rahul.resident@community.org";
    } else if (newRole === "School / College In-charge") {
      this.user.name = "Principal Sharma";
      this.user.email = "principal@modelschool.edu";
    } else if (newRole === "Administrator") {
      this.user.name = "Admin Alok";
      this.user.email = "admin@smartmosquito.org";
    } else if (newRole === "Student Researcher") {
      this.user.name = "Alok (Student - IT)";
      this.user.email = "alok.student@college.edu";
    } else {
      this.user.name = "Dr. Alok Verma";
      this.user.email = "alok.verma@health.gov.in";
    }
    this.renderProfileScreen();
    this.showToast(`Active User: ${this.user.name} (${newRole})`);
  }

  openCitizenReportModal() {
    if (window.soundFx) window.soundFx.playClick();
    const modal = document.getElementById("citizen-report-modal");
    if (modal) modal.classList.add("active");
  }

  async submitCitizenReport() {
    const hazardType = document.getElementById("cit-hazard-type").value;
    const location = document.getElementById("cit-location").value.trim() || "Sector 4";
    const desc = document.getElementById("cit-desc").value.trim();

    const note = `${hazardType} reported by ${this.user.name}: ${desc}`;
    
    // Inject caution/danger reading tagged to citizen report location
    await API.simulate("danger");

    this.closeModal("citizen-report-modal");
    if (window.soundFx) window.soundFx.playSuccess();
    this.showToast(`📢 Report submitted for "${location}"! Health squad notified.`);
    this.refreshData();
    this.renderAlertsScreen();
  }

  _initTheme() {
    const isDark = localStorage.getItem("mosquito_theme") === "dark";
    if (isDark) {
      document.body.classList.add("dark-mode");
      const toggle = document.getElementById("theme-toggle-chk");
      if (toggle) toggle.checked = true;
    }
  }

  toggleDarkMode(enable) {
    if (enable) {
      document.body.classList.add("dark-mode");
      localStorage.setItem("mosquito_theme", "dark");
    } else {
      document.body.classList.remove("dark-mode");
      localStorage.setItem("mosquito_theme", "light");
    }
    if (window.soundFx) window.soundFx.playClick();
  }

  toggleSoundFx(enable) {
    if (window.soundFx) {
      window.soundFx.setSoundEnabled(enable);
      this.showToast(enable ? "🔊 Sound effects enabled" : "🔇 Sound effects muted");
    }
  }

  async injectScenario(scenario) {
    const res = await API.simulate(scenario);
    if (res.success) {
      if (window.soundFx) {
        if (scenario === "danger") window.soundFx.playBuzzerAlarm();
        else window.soundFx.playSuccess();
      }
      this.showToast(`⚡ Injected IoT Scenario: ${scenario.toUpperCase()}`);
      this.refreshData();
      if (this.currentScreen === "screen-alerts") this.renderAlertsScreen();
      if (this.currentScreen === "screen-history") this.renderHistoryScreen();
    }
  }

  // --------------------------------------------------------------------------
  // Event Bindings & Helpers
  // --------------------------------------------------------------------------
  _bindEvents() {
    // Navigation Tabs Click
    document.querySelectorAll(".nav-tab-item").forEach(tab => {
      tab.addEventListener("click", () => {
        const targetScreen = tab.dataset.screen;
        if (targetScreen) this.showScreen(targetScreen);
      });
    });

    // Alert filter chips
    document.querySelectorAll(".filter-chip").forEach(chip => {
      chip.addEventListener("click", (e) => {
        document.querySelectorAll(".filter-chip").forEach(c => c.classList.remove("active"));
        chip.classList.add("active");
        const status = chip.dataset.status || "all";
        this.renderAlertsScreen(status);
      });
    });
  }

  showToast(message) {
    const container = document.getElementById("toast-container");
    if (!container) return;

    const toast = document.createElement("div");
    toast.className = "toast-message";
    toast.innerHTML = `<span>🦟</span> <span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = "0";
      toast.style.transform = "translateY(-10px)";
      setTimeout(() => toast.remove(), 300);
    }, 3200);
  }

  _timeAgo(isoString) {
    if (!isoString) return "Just now";
    const diff = (Date.now() - new Date(isoString).getTime()) / 1000;
    if (diff < 60) return "Just now";
    if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
    return `${Math.floor(diff / 86400)}d ago`;
  }
}

// Global App Instance
window.app = new MosquitoApp();
document.addEventListener("DOMContentLoaded", () => {
  window.app.init();
});
