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
        final data = response.data as Map<String, dynamic>;
        
        // Check if device is actually connected
        final device = data['device'] as Map<String, dynamic>?;
        if (device == null || device.isEmpty) {
          throw Exception('No hardware device connected');
        }
        
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
        return response.data as List<dynamic>;
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
        '/api/pump',
        data: {'enable': enable},
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to control pump');
    } catch (e) {
      throw Exception('API Error: $e');
    }
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
      final data = response.data as Map<String, dynamic>;
      
      // Device is connected if we get valid device data
      final device = data['device'] as Map<String, dynamic>?;
      final isConnected = device != null && device.isNotEmpty;
      
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
