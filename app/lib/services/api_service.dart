import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  static String get tokenKey => dotenv.env['JWT_TOKEN_KEY'] ?? 'jwt_token';
  
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // 토큰 저장 (보안 저장소 우선, 실패 시 일반 저장소)
  static Future<void> saveToken(String token) async {
    try {
      await _secureStorage.write(key: tokenKey, value: token);
    } catch (e) {
      // Secure storage 실패 시 SharedPreferences 사용
      print('Secure storage failed, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
    }
  }

  // 토큰 조회 (보안 저장소 우선, 실패 시 일반 저장소)
  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: tokenKey);
    } catch (e) {
      // Secure storage 실패 시 SharedPreferences 사용
      print('Secure storage failed, using SharedPreferences: $e');
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(tokenKey);
    }
  }

  // 토큰 삭제 (보안 저장소 우선, 실패 시 일반 저장소)
  static Future<void> deleteToken() async {
    try {
      await _secureStorage.delete(key: tokenKey);
    } catch (e) {
      print('Secure storage failed, using SharedPreferences: $e');
    }
    
    // 항상 SharedPreferences도 확인하여 삭제
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(tokenKey);
    } catch (e) {
      print('SharedPreferences delete failed: $e');
    }
  }

  // 기본 헤더 생성
  static Future<Map<String, String>> _getHeaders({bool includeAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (includeAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // GET 요청
  static Future<http.Response> get(String endpoint, {bool requireAuth = false}) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await http.get(uri, headers: headers);
  }

  // POST 요청
  static Future<http.Response> post(
    String endpoint, 
    Map<String, dynamic> data, 
    {bool requireAuth = false}
  ) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    );
  }

  // PUT 요청
  static Future<http.Response> put(
    String endpoint, 
    Map<String, dynamic> data, 
    {bool requireAuth = false}
  ) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await http.put(
      uri,
      headers: headers,
      body: json.encode(data),
    );
  }

  // PATCH 요청
  static Future<http.Response> patch(
    String endpoint, 
    Map<String, dynamic> data, 
    {bool requireAuth = false}
  ) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await http.patch(
      uri,
      headers: headers,
      body: json.encode(data),
    );
  }

  // DELETE 요청
  static Future<http.Response> delete(String endpoint, {bool requireAuth = false}) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await http.delete(uri, headers: headers);
  }

  // 응답 처리 헬퍼
  static dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
} 