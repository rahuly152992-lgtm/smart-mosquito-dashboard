/**
 * api.js
 * ------
 * Client-side communication layer for the Smart Mosquito Breeding Detection System.
 * Connects the mobile frontend with the Flask REST API & Firebase backend.
 */

const API = {
  baseUrl: "",
  requestTimeoutMs: 10000,
  maxRetries: 4,

  async _fetchJson(path, options = {}) {
    let lastError;

    for (let attempt = 0; attempt <= this.maxRetries; attempt += 1) {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.requestTimeoutMs);

      try {
        const res = await fetch(`${this.baseUrl}${path}`, { ...options, signal: controller.signal });
        if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
        return await res.json();
      } catch (err) {
        lastError = err;
        if (attempt === this.maxRetries) break;

        const retryNumber = attempt + 1;
        if (window.app && typeof window.app.setBackendStatus === "function") {
          window.app.setBackendStatus(`Backend is waking up... retrying (${retryNumber}/${this.maxRetries})`);
        }
        await new Promise(resolve => setTimeout(resolve, Math.min(1500 * (2 ** attempt), 8000)));
      } finally {
        clearTimeout(timeoutId);
      }
    }

    throw lastError;
  },

  async getLatest() {
    try {
      return await this._fetchJson("/api/latest");
    } catch (err) {
      console.warn("API getLatest error, using cached/fallback state:", err);
      return null;
    }
  },

  async getRecords(risk = "all", timeRange = "all", limit = 50) {
    try {
      const url = `${this.baseUrl}/api/records?risk=${encodeURIComponent(risk)}&time_range=${encodeURIComponent(timeRange)}&limit=${limit}`;
      return await this._fetchJson(url);
    } catch (err) {
      console.warn("API getRecords error:", err);
      return [];
    }
  },

  async getAlerts(status = "all") {
    try {
      return await this._fetchJson(`/api/alerts?status=${encodeURIComponent(status)}`);
    } catch (err) {
      console.warn("API getAlerts error:", err);
      return [];
    }
  },

  async getAlertDetails(alertId) {
    try {
      return await this._fetchJson(`/api/alerts/${encodeURIComponent(alertId)}`);
    } catch (err) {
      console.warn("API getAlertDetails error:", err);
      return null;
    }
  },

  async resolveAlert(alertId, resolvedBy, note) {
    try {
      return await this._fetchJson(`/api/alerts/${encodeURIComponent(alertId)}/resolve`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ resolved_by: resolvedBy, note: note })
      });
    } catch (err) {
      console.error("API resolveAlert error:", err);
      return { success: false, error: err.message };
    }
  },

  async logAlertAction(alertId, actor, note, markCleaned = false, markResolved = false) {
    try {
      return await this._fetchJson(`/api/alerts/${encodeURIComponent(alertId)}/action`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          actor: actor,
          note: note,
          mark_cleaned: markCleaned,
          mark_resolved: markResolved
        })
      });
    } catch (err) {
      console.error("API logAlertAction error:", err);
      return { success: false, error: err.message };
    }
  },

  async submitCitizenReport(location, hazardType, description) {
    try {
      return await this._fetchJson("/api/alerts/report", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          location: location,
          hazard_type: hazardType,
          description: description
        })
      });
    } catch (err) {
      console.error("API submitCitizenReport error:", err);
      return { success: false, error: err.message };
    }
  },

  async getDevice() {
    try {
      return await this._fetchJson("/api/device");
    } catch (err) {
      console.warn("API getDevice error:", err);
      return null;
    }
  },

  async controlPump(mode, state) {
    try {
      return await this._fetchJson("/api/device/control", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ pump_mode: mode, pump_state: state })
      });
    } catch (err) {
      console.error("API controlPump error:", err);
      return { success: false, error: err.message };
    }
  },

  async simulate(scenario) {
    try {
      return await this._fetchJson("/api/simulate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ scenario: scenario })
      });
    } catch (err) {
      console.error("API simulate error:", err);
      return { success: false, error: err.message };
    }
  },

  async getStats() {
    try {
      return await this._fetchJson("/api/stats");
    } catch (err) {
      console.warn("API getStats error:", err);
      return null;
    }
  },

  async getConfig() {
    try {
      return await this._fetchJson("/api/config");
    } catch (err) {
      return null;
    }
  },

  async saveConfig(configData) {
    try {
      return await this._fetchJson("/api/config", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(configData)
      });
    } catch (err) {
      return { error: err.message };
    }
  }
};

window.API = API;
