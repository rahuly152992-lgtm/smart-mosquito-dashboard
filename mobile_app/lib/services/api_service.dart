import 'package:dio/dio.dart';

class ApiService {
  late Dio _dio;
  static const String baseUrl = 'https://smart-mosquito-dashboard-1.onrender.com';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
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
        
        return data;
      }
      throw Exception('Failed to fetch data: ${response.statusCode}');
    } catch (e) {
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

  /// Check hardware connection status
  Future<bool> checkConnection() async {
    try {
      final response = await _dio.get('/api/latest');
      final data = response.data as Map<String, dynamic>;
      
      // Device is connected if we get valid device data
      final device = data['device'] as Map<String, dynamic>?;
      return device != null && device.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
