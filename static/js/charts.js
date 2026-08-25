/**
 * charts.js
 * ---------
 * Chart.js visualization engine for the Smart Mosquito Breeding Detection System.
 * Renders live sensor telemetry curves, history trends, and risk distribution charts.
 */

class TelemetryCharts {
  constructor() {
    this.liveChart = null;
    this.historyChart = null;
    this.riskDistChart = null;
  }

  initLiveTelemetryChart(canvasId, initialRecords = []) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || typeof Chart === "undefined") return;

    const ctx = canvas.getContext("2d");
    if (this.liveChart) {
      this.liveChart.destroy();
    }

    const records = (initialRecords || []).slice(-15);
    const labels = records.map(r => {
      const d = new Date(r.Timestamp || Date.now());
      return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
    });
    const waterData = records.map(r => r.WaterLevel || 0);
    const tempData = records.map(r => r.Temperature || 0);
    const humData = records.map(r => r.Humidity || 0);

    const isDark = document.body.classList.contains("dark-mode");
    const gridColor = isDark ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.06)";
    const textColor = isDark ? "#94a3b8" : "#64748b";

    this.liveChart = new Chart(ctx, {
      type: "line",
      data: {
        labels: labels.length ? labels : ["Now"],
        datasets: [
          {
            label: "Water Level (%)",
            data: waterData.length ? waterData : [78],
            borderColor: "#0284c7",
            backgroundColor: "rgba(2, 132, 199, 0.15)",
            fill: true,
            tension: 0.35,
            borderWidth: 2.5,
            pointRadius: 3,
            pointHoverRadius: 6,
            yAxisID: "yWater"
          },
          {
            label: "Temp (°C)",
            data: tempData.length ? tempData : [29],
            borderColor: "#f59e0b",
            backgroundColor: "transparent",
            tension: 0.35,
            borderWidth: 2,
            pointRadius: 2.5,
            yAxisID: "yEnv"
          },
          {
            label: "Humidity (%)",
            data: humData.length ? humData : [76],
            borderColor: "#10b981",
            backgroundColor: "transparent",
            tension: 0.35,
            borderWidth: 2,
            pointRadius: 2.5,
            yAxisID: "yWater"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: "index",
          intersect: false
        },
        plugins: {
          legend: {
            position: "top",
            labels: {
              boxWidth: 12,
              font: { family: "'Segoe UI', sans-serif", size: 11, weight: "600" },
              color: textColor
            }
          },
          tooltip: {
            backgroundColor: "rgba(15, 23, 42, 0.9)",
            titleFont: { size: 12, weight: "bold" },
            bodyFont: { size: 11 },
            padding: 10,
            cornerRadius: 8
          }
        },
        scales: {
          x: {
            grid: { color: gridColor },
            ticks: { color: textColor, font: { size: 10 } }
          },
          yWater: {
            type: "linear",
            position: "left",
            min: 0,
            max: 100,
            grid: { color: gridColor },
            ticks: { color: textColor, font: { size: 10 }, callback: v => v + "%" },
            title: { display: true, text: "Water & Humidity", color: textColor, font: { size: 10 } }
          },
          yEnv: {
            type: "linear",
            position: "right",
            min: 10,
            max: 45,
            grid: { drawOnChartArea: false },
            ticks: { color: "#f59e0b", font: { size: 10 }, callback: v => v + "°C" },
            title: { display: true, text: "Temperature", color: "#f59e0b", font: { size: 10 } }
          }
        }
      }
    });
  }

  updateLiveTelemetry(newRecord) {
    if (!this.liveChart || !newRecord) return;
    const timeLabel = new Date(newRecord.Timestamp || Date.now()).toLocaleTimeString([], {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit"
    });

    const chart = this.liveChart;
    chart.data.labels.push(timeLabel);
    chart.data.datasets[0].data.push(newRecord.WaterLevel);
    chart.data.datasets[1].data.push(newRecord.Temperature);
    chart.data.datasets[2].data.push(newRecord.Humidity);

    // Keep last 15 points
    if (chart.data.labels.length > 15) {
      chart.data.labels.shift();
      chart.data.datasets.forEach(ds => ds.data.shift());
    }

    chart.update("none");
  }

  initHistoryTrendChart(canvasId, records = []) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || typeof Chart === "undefined") return;

    const ctx = canvas.getContext("2d");
    if (this.historyChart) {
      this.historyChart.destroy();
    }

    const isDark = document.body.classList.contains("dark-mode");
    const gridColor = isDark ? "rgba(255, 255, 255, 0.08)" : "rgba(0, 0, 0, 0.06)";
    const textColor = isDark ? "#94a3b8" : "#64748b";

    const displayRecords = records.slice(0, 30).reverse();
    const labels = displayRecords.map(r => {
      const d = new Date(r.Timestamp || Date.now());
      return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours()}:${String(d.getMinutes()).padStart(2, "0")}`;
    });

    this.historyChart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: labels,
        datasets: [
          {
            label: "Water Level (%)",
            data: displayRecords.map(r => r.WaterLevel),
            backgroundColor: displayRecords.map(r => {
              if (r.RiskLabel === "danger") return "rgba(239, 68, 68, 0.85)";
              if (r.RiskLabel === "caution") return "rgba(245, 158, 11, 0.85)";
              return "rgba(16, 185, 129, 0.85)";
            }),
            borderRadius: 4
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              afterLabel: (item) => {
                const r = displayRecords[item.dataIndex];
                return `Temp: ${r.Temperature}°C | Hum: ${r.Humidity}% | Risk: ${r.RiskLabel?.toUpperCase()}`;
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: textColor, font: { size: 9 }, maxRotation: 45 }
          },
          y: {
            min: 0,
            max: 100,
            grid: { color: gridColor },
            ticks: { color: textColor, font: { size: 10 }, callback: v => v + "%" }
          }
        }
      }
    });
  }

  initRiskDistChart(canvasId, stats = {}) {
    const canvas = document.getElementById(canvasId);
    if (!canvas || typeof Chart === "undefined") return;

    const ctx = canvas.getContext("2d");
    if (this.riskDistChart) {
      this.riskDistChart.destroy();
    }

    const activeCount = stats.active_alerts || 2;
    const resolvedCount = stats.resolved_alerts || 2;
    const safeCount = Math.max(1, (stats.total_alerts || 4) * 2);

    this.riskDistChart = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: ["Active Risk", "Resolved", "Safe Monitored"],
        datasets: [
          {
            data: [activeCount, resolvedCount, safeCount],
            backgroundColor: ["#ef4444", "#10b981", "#38bdf8"],
            borderWidth: 2,
            borderColor: document.body.classList.contains("dark-mode") ? "#1e293b" : "#ffffff"
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "70%",
        plugins: {
          legend: {
            position: "bottom",
            labels: {
              boxWidth: 10,
              font: { size: 11, weight: "600" },
              color: document.body.classList.contains("dark-mode") ? "#94a3b8" : "#64748b"
            }
          }
        }
      }
    });
  }
}

window.telemetryCharts = new TelemetryCharts();
