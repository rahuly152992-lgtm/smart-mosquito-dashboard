/**
 * api.js
 * ------
 * Client-side communication layer for the Smart Mosquito Breeding Detection System.
 * Connects the mobile frontend with the Flask REST API & Firebase backend.
 */

const API = {
  baseUrl: "",

  async getLatest() {
    try {
      const res = await fetch(`${this.baseUrl}/api/latest`);
      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
      return await res.json();
    } catch (err) {
      console.warn("API getLatest error, using cached/fallback state:", err);
      return null;
    }
  },

  async getRecords(risk = "all", timeRange = "all", limit = 50) {
    try {
      const url = `${this.baseUrl}/api/records?risk=${encodeURIComponent(risk)}&time_range=${encodeURIComponent(timeRange)}&limit=${limit}`;
      const res = await fetch(url);
      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
      return await res.json();
    } catch (err) {
      console.warn("API getRecords error:", err);
      return [];
    }
  },

  async getAlerts(status = "all") {
    try {
      const res = await fetch(`${this.baseUrl}/api/alerts?status=${encodeURIComponent(status)}`);
      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
      return await res.json();
    } catch (err) {
      console.warn("API getAlerts error:", err);
      return [];
    }
  },

  async getAlertDetails(alertId) {
    try {
      const res = await fetch(`${this.baseUrl}/api/alerts/${encodeURIComponent(alertId)}`);
      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
      return await res.json();
    } catch (err) {
      console.warn("API getAlertDetails error:", err);
      return null;
    }
  },

  async resolveAlert(alertId, resolvedBy, note) {
    try {
      const res = await fetch(`${this.baseUrl}/api/alerts/${encodeURIComponent(alertId)}/resolve`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ resolved_by: resolvedBy, note: note })
      });
      return await res.json();
    } catch (err) {
      console.error("API resolveAlert error:", err);
      return { success: false, error: err.message };
    }
  },

  async logAlertAction(alertId, actor, note, markCleaned = false, markResolved = false) {
    try {
      const res = await fetch(`${this.baseUrl}/api/alerts/${encodeURIComponent(alertId)}/action`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          actor: actor,
          note: note,
          mark_cleaned: markCleaned,
          mark_resolved: markResolved
        })
      });
      return await res.json();
    } catch (err) {
      console.error("API logAlertAction error:", err);
      return { success: false, error: err.message };
    }
  },

  async getDevice() {
    try {
      const res = await fetch(`${this.baseUrl}/api/device`);
      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
      return await res.json();
    } catch (err) {
      console.warn("API getDevice error:", err);
      return null;
    }
  },

  async controlPump(mode, state) {
    try {
      const res = await fetch(`${this.baseUrl}/api/pump/control`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ mode: mode, state: state })
      });
      return await res.json();
    } catch (err) {
      console.error("API controlPump error:", err);
      return { success: false, error: err.message };
    }
  },

  async simulate(scenario) {
    try {
      const res = await fetch(`${this.baseUrl}/api/simulate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ scenario: scenario })
      });
      return await res.json();
    } catch (err) {
      console.error("API simulate error:", err);
      return { success: false, error: err.message };
    }
  },

  async getStats() {
    try {
      const res = await fetch(`${this.baseUrl}/api/stats`);
      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);
      return await res.json();
    } catch (err) {
      console.warn("API getStats error:", err);
      return null;
    }
  },

  async getConfig() {
    try {
      const res = await fetch(`${this.baseUrl}/api/config`);
      return await res.json();
    } catch (err) {
      return null;
    }
  },

  async saveConfig(configData) {
    try {
      const res = await fetch(`${this.baseUrl}/api/config`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(configData)
      });
      return await res.json();
    } catch (err) {
      return { error: err.message };
    }
  }
};

window.API = API;
