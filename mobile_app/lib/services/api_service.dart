import 'package:dio/dio.dart';

class ApiService {
  late Dio _dio;
  static const String baseUrl = 'https://smart-mosquito-dashboard-1.onrender.com';
  
  // Cache latest data to show immediately on startup
  Map<String, dynamic>? _cachedData;
  DateTime? _cacheTime;
  static const Duration _cacheValidity = Duration(seconds: 30);

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Map<String, dynamic> _normalizeRecord(Map<String, dynamic> record) {
    return {
      ...record,
      'water_level': record['WaterLevel'] ?? record['water_level'],
      'temperature': record['Temperature'] ?? record['temperature'],
      'humidity': record['Humidity'] ?? record['humidity'],
      'image_risk_score': record['ImageRiskScore'] ?? record['image_risk_score'],
      'risk_score': record['RiskScore'] ?? record['risk_score'],
      'risk_level': record['RiskLabel'] ?? record['risk_level'] ?? 'unknown',
      'timestamp': record['Timestamp'] ?? record['timestamp'],
      'alerts': record['Reasons'] ?? record['alerts'] ?? const <String>[],
    };
  }

  Map<String, dynamic> _normalizeDevice(Map<String, dynamic> device) {
    return {
      ...device,
      'name': device['device_name'] ?? device['name'] ?? 'ESP32 Node',
      'status': device['status'] ?? 'offline',
      'rssi': device['wifi_rssi'] ?? device['rssi'],
      'pump_state': device['pump_state'] ?? 'OFF',
    };
  }
  
  /// Get cached data if available and fresh
  Map<String, dynamic>? getCachedData() {
    if (_cachedData != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!).inSeconds < _cacheValidity.inSeconds) {
        return _cachedData;
      }
    }
    return null;
  }

  /// Check if backend is alive (lightweight health check)
  Future<bool> checkHealth() async {
    try {
      final response = await _dio.get(
        '/api/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get latest sensor reading from ESP32
  Future<Map<String, dynamic>> getLatestReading() async {
    try {
      final response = await _dio.get('/api/latest');
      
      if (response.statusCode == 200) {
        final rawData = Map<String, dynamic>.from(response.data as Map);
        final rawRecord = rawData['record'];
        final rawDevice = rawData['device'];
        final data = <String, dynamic>{
          ...rawData,
          'record': rawRecord is Map
              ? _normalizeRecord(Map<String, dynamic>.from(rawRecord))
              : <String, dynamic>{},
          'device': rawDevice is Map
              ? _normalizeDevice(Map<String, dynamic>.from(rawDevice))
              : <String, dynamic>{},
        };
        
        // Cache the successful response
        _cachedData = data;
        _cacheTime = DateTime.now();
        
        return data;
      }
      throw Exception('Failed to fetch data: ${response.statusCode}');
    } catch (e) {
      // Return cached data if API fails
      if (_cachedData != null) {
        return _cachedData!;
      }
      throw Exception('API Error: $e');
    }
  }

  /// Get historical records
  Future<List<dynamic>> getRecords({int limit = 100}) async {
    try {
      final response = await _dio.get(
        '/api/records',
        queryParameters: {'limit': limit},
      );
      
      if (response.statusCode == 200) {
        final records = response.data as List<dynamic>;
        return records.map((record) => _normalizeRecord(
          Map<String, dynamic>.from(record as Map),
        )).toList();
      }
      throw Exception('Failed to fetch records');
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  /// Get device status
  Future<Map<String, dynamic>> getDeviceStatus() async {
    try {
      final response = await _dio.get('/api/device');
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch device status');
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  /// Trigger pump control
  Future<Map<String, dynamic>> controlPump(bool enable) async {
    try {
      final response = await _dio.post(
        '/api/device/control',
        data: {'pump_mode': 'manual', 'pump_state': enable ? 'ON' : 'OFF'},
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to control pump');
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<List<dynamic>> getAlerts({String status = 'all'}) async {
    final response = await _dio.get(
      '/api/alerts',
      queryParameters: {'status': status},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> resolveAlert(String alertId, String resolvedBy) async {
    final response = await _dio.post(
      '/api/alerts/${Uri.encodeComponent(alertId)}/resolve',
      data: {'resolved_by': resolvedBy, 'note': 'Resolved from the mobile app.'},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> simulate(String scenario) async {
    final response = await _dio.post('/api/simulate', data: {'scenario': scenario});
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get('/api/stats');
    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Check hardware connection status (with fast timeout)
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get(
        '/api/latest',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      
      // Device is connected if we get valid device data
        final rawDevice = data['device'];
        final device = rawDevice is Map
          ? _normalizeDevice(Map<String, dynamic>.from(rawDevice))
          : null;
        final isConnected = device != null &&
          device.isNotEmpty && device['status'] == 'connected';
      
      if (isConnected) {
        // Cache successful data
        _cachedData = data;
        _cacheTime = DateTime.now();
      }
      
      return isConnected;
    } catch (e) {
      // If we have cache, consider it still connected (for better UX)
      return _cachedData != null;
    }
  }
}
