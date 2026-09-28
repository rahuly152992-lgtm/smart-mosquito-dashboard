import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/api_service.dart';

class SensorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _latestReading;
  Map<String, dynamic>? _deviceStatus;
  Map<String, dynamic> _stats = {};
  List<dynamic> _alerts = [];
  List<dynamic> _records = [];

  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get latestReading => _latestReading;
  Map<String, dynamic>? get deviceStatus => _deviceStatus;
  List<dynamic> get records => _records;
  Map<String, dynamic> get stats => _stats;
  List<dynamic> get alerts => _alerts;

  /// Check if hardware is connected and fetch latest data in background
  /// Never blocks the UI or shows a full-screen loading spinner
  Future<void> checkAndFetchData({bool isInitialLoad = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final isHealthy = await _apiService.checkHealth();
      
      if (!isHealthy && !isInitialLoad) {
        _isConnected = false;
        _error = 'Connecting to backend...';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _apiService.getLatestReading().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          final cached = _apiService.getCachedData();
          if (cached != null) return cached;
          return {
            'record': _latestReading,
            'device': _deviceStatus,
          };
        },
      );
      
      if (data['record'] != null) {
        _latestReading = data['record'] as Map<String, dynamic>?;
      }
      if (data['device'] != null) {
        _deviceStatus = data['device'] as Map<String, dynamic>?;
      }
      _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
      _isConnected = _deviceStatus?['status'] == 'connected';
      if (_isConnected) {
        await fetchAlerts();
      }
      _error = null;
      
    } catch (e) {
      // Keep existing data, don't break the UI
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch historical records
  Future<void> fetchRecords({int limit = 100}) async {
    try {
      _records = await _apiService.getRecords(limit: limit);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAlerts({String status = 'all'}) async {
    try {
      _alerts = await _apiService.getAlerts(status: status);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> resolveAlert(String alertId, String resolvedBy) async {
    try {
      final result = await _apiService.resolveAlert(alertId, resolvedBy);
      if (result['success'] == true) {
        await fetchAlerts();
        await checkAndFetchData();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  Future<bool> simulate(String scenario) async {
    try {
      final result = await _apiService.simulate(scenario);
      if (result['success'] == true) {
        await checkAndFetchData();
        await fetchRecords();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
    return false;
  }

  /// Control pump
  Future<bool> controlPump(bool enable) async {
    try {
      final result = await _apiService.controlPump(enable);
      if (result['success'] == true) {
        _deviceStatus = Map<String, dynamic>.from(result['device'] as Map);
        notifyListeners();
        return true;
      }
      _error = result['error']?.toString() ?? 'Pump control failed';
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
