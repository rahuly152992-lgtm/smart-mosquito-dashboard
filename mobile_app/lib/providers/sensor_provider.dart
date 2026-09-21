import 'package:flutter/foundation.dart';
import 'dart:async';
import '../services/api_service.dart';

class SensorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isConnected = true;
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _latestReading = {
    'temperature': 28.5,
    'humidity': 65.0,
    'risk_level': 'SAFE',
    'water_detected': false,
    'timestamp': 'Just now',
    'alerts': ['Budget Threshold Breached - System Active']
  };

  Map<String, dynamic>? _deviceStatus = {
    'name': 'ESP32 Node #1',
    'status': 'online',
    'ip': '192.168.1.108',
    'rssi': -64
  };

  List<dynamic> _records = [];

  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get latestReading => _latestReading;
  Map<String, dynamic>? get deviceStatus => _deviceStatus;
  List<dynamic> get records => _records;

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
      _isConnected = true;
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

  /// Control pump
  Future<bool> controlPump(bool enable) async {
    try {
      await _apiService.controlPump(enable);
      return true;
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
