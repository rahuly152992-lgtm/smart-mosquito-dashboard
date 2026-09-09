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
  List<dynamic> _records = [];

  // Getters
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get latestReading => _latestReading;
  Map<String, dynamic>? get deviceStatus => _deviceStatus;
  List<dynamic> get records => _records;

  /// Check if hardware is connected and fetch latest data
  /// Uses health check first for faster feedback on slow backends
  Future<void> checkAndFetchData({bool isInitialLoad = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First do a health check (very fast, <1s)
      // This tells us if server is alive even if it's slow
      final isHealthy = await _apiService.checkHealth();
      
      if (!isHealthy && !isInitialLoad) {
        _isConnected = false;
        _error = 'Backend not responding';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Now fetch the actual data with reasonable timeout
      final data = await _apiService.getLatestReading().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // If timeout, check if we have cached data
          final cached = _apiService.getCachedData();
          if (cached != null) {
            return cached;
          }
          throw TimeoutException('Connection timeout - backend is slow to respond');
        },
      );
      
      _latestReading = data['record'] as Map<String, dynamic>?;
      _deviceStatus = data['device'] as Map<String, dynamic>?;
      _isConnected = true;
      _error = null;
      
    } on TimeoutException catch (e) {
      _isConnected = false;
      _error = e.message;
    } catch (e) {
      _isConnected = false;
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

  /// Reset connection state
  void reset() {
    _isConnected = false;
    _latestReading = null;
    _deviceStatus = null;
    _records = [];
    _error = null;
    notifyListeners();
  }
}
