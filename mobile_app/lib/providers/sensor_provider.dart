import 'package:flutter/foundation.dart';
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
  Future<void> checkAndFetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First check if connected
      final connected = await _apiService.checkConnection();
      
      if (!connected) {
        _isConnected = false;
        _error = 'Hardware not connected';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch latest data
      final data = await _apiService.getLatestReading();
      
      _latestReading = data['record'] as Map<String, dynamic>?;
      _deviceStatus = data['device'] as Map<String, dynamic>?;
      _isConnected = true;
      _error = null;
      
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
