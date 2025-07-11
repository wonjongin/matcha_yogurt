import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String get baseUrl {
    // 1. 플랫폼별 환경변수 우선 확인
    String? envUrl;
    
    if (kIsWeb) {
      // 웹 환경
      envUrl = dotenv.env['API_BASE_URL_WEB'] ?? dotenv.env['API_BASE_URL'];
    } else {
      // 모바일/데스크톱 환경
      try {
        if (Platform.isAndroid) {
          // Android용 환경변수 확인
          envUrl = dotenv.env['API_BASE_URL_ANDROID'] ?? dotenv.env['API_BASE_URL'];
        } else if (Platform.isIOS) {
          // iOS용 환경변수 확인
          envUrl = dotenv.env['API_BASE_URL_IOS'] ?? dotenv.env['API_BASE_URL'];
        } else {
          // 기타 플랫폼 (데스크톱 등)
          envUrl = dotenv.env['API_BASE_URL_DESKTOP'] ?? dotenv.env['API_BASE_URL'];
        }
      } catch (e) {
        // Platform 접근 실패 시 기본값 사용
        envUrl = dotenv.env['API_BASE_URL'];
      }
    }
    
    // 2. 환경변수가 설정되어 있으면 사용
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 3. 환경변수가 없으면 플랫폼별 기본값 사용
    if (kIsWeb) {
      // 웹: localhost
      return 'http://localhost:3000';
    } else {
      try {
        if (Platform.isAndroid) {
          // Android 에뮬레이터: 10.0.2.2 (호스트 머신 접근)
          return 'http://10.0.2.2:3000';
        } else if (Platform.isIOS) {
          // iOS 시뮬레이터: localhost
          return 'http://localhost:3000';
        } else {
          // 데스크톱: localhost
          return 'http://localhost:3000';
        }
      } catch (e) {
        // Platform 접근 실패 시 기본값
        return 'http://localhost:3000';
      }
    }
  }
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
    if (kIsWeb) {
      // 웹에서는 SharedPreferences만 사용
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, token);
    } else {
      try {
        await _secureStorage.write(key: tokenKey, value: token);
      } catch (e) {
        // Secure storage 실패 시 SharedPreferences 사용
        print('Secure storage failed, using SharedPreferences: $e');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(tokenKey, token);
      }
    }
  }

  // 토큰 조회 (보안 저장소 우선, 실패 시 일반 저장소)
  static Future<String?> getToken() async {
    if (kIsWeb) {
      // 웹에서는 SharedPreferences만 사용
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(tokenKey);
    } else {
      try {
        return await _secureStorage.read(key: tokenKey);
      } catch (e) {
        // Secure storage 실패 시 SharedPreferences 사용
        print('Secure storage failed, using SharedPreferences: $e');
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(tokenKey);
      }
    }
  }

  // 토큰 삭제 (보안 저장소 우선, 실패 시 일반 저장소)
  static Future<void> deleteToken() async {
    if (kIsWeb) {
      // 웹에서는 SharedPreferences만 사용
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(tokenKey);
      } catch (e) {
        print('SharedPreferences delete failed: $e');
      }
    } else {
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
    
    return await _handleRequest(() => http.get(uri, headers: headers));
  }

  // POST 요청
  static Future<http.Response> post(
    String endpoint, 
    Map<String, dynamic> data, 
    {bool requireAuth = false}
  ) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await _handleRequest(() => http.post(
      uri,
      headers: headers,
      body: json.encode(data),
    ));
  }

  // PUT 요청
  static Future<http.Response> put(
    String endpoint, 
    Map<String, dynamic> data, 
    {bool requireAuth = false}
  ) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await _handleRequest(() => http.put(
      uri,
      headers: headers,
      body: json.encode(data),
    ));
  }

  // PATCH 요청
  static Future<http.Response> patch(
    String endpoint, 
    Map<String, dynamic> data, 
    {bool requireAuth = false}
  ) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await _handleRequest(() => http.patch(
      uri,
      headers: headers,
      body: json.encode(data),
    ));
  }

  // DELETE 요청
  static Future<http.Response> delete(String endpoint, {bool requireAuth = false}) async {
    final headers = await _getHeaders(includeAuth: requireAuth);
    final uri = Uri.parse('$baseUrl$endpoint');
    
    return await _handleRequest(() => http.delete(uri, headers: headers));
  }

  // 응답 처리 헬퍼
  static dynamic handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body);
      } catch (e) {
        throw Exception('서버 응답을 처리할 수 없습니다');
      }
    } else {
      // 에러 응답 처리
      String errorMessage = _getErrorMessage(response);
      throw Exception(errorMessage);
    }
  }

  // 에러 메시지 생성 (한국어)
  static String _getErrorMessage(http.Response response) {
    try {
      // 백엔드에서 온 에러 메시지 파싱 시도
      final errorData = json.decode(response.body);
      
      // 백엔드에서 한국어 메시지를 보낸 경우
      if (errorData['message'] != null) {
        String message = errorData['message'];
        
        // 영어 메시지를 한국어로 변환
        message = _translateErrorMessage(message);
        return message;
      }
    } catch (e) {
      // JSON 파싱 실패 시 HTTP 상태 코드 기반 메시지
    }

    // HTTP 상태 코드별 기본 한국어 메시지
    switch (response.statusCode) {
      case 400:
        return '잘못된 요청입니다. 입력 정보를 확인해주세요.';
      case 401:
        return '인증이 필요합니다. 다시 로그인해주세요.';
      case 403:
        return '접근 권한이 없습니다.';
      case 404:
        return '요청한 정보를 찾을 수 없습니다.';
      case 409:
        return '이미 존재하는 정보입니다.';
      case 422:
        return '입력한 정보가 올바르지 않습니다.';
      case 429:
        return '너무 많은 요청을 보냈습니다. 잠시 후 다시 시도해주세요.';
      case 500:
        return '서버에 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
      case 502:
        return '서버 연결에 문제가 있습니다.';
      case 503:
        return '서비스를 일시적으로 사용할 수 없습니다.';
      default:
        return '알 수 없는 오류가 발생했습니다. (${response.statusCode})';
    }
  }

  // 영어 에러 메시지를 한국어로 변환
  static String _translateErrorMessage(String message) {
    // 자주 나오는 영어 에러 메시지들을 한국어로 변환
    final translations = {
      'Email already exists': '이미 사용 중인 이메일입니다.',
      'Invalid credentials': '이메일 또는 비밀번호가 올바르지 않습니다.',
      'User not found': '존재하지 않는 사용자입니다.',
      'Please verify your email before logging in': '로그인하기 전에 이메일 인증을 완료해주세요.',
      'Invalid or expired verification token': '유효하지 않거나 만료된 인증 토큰입니다.',
      'Failed to send verification email': '인증 이메일 발송에 실패했습니다.',
      'Team not found': '존재하지 않는 팀입니다.',
      'You are not a member of this team': '이 팀의 멤버가 아닙니다.',
      'Insufficient permissions': '권한이 부족합니다.',
      'Invalid token': '유효하지 않은 토큰입니다.',
      'Token expired': '토큰이 만료되었습니다.',
      'Network error': '네트워크 연결을 확인해주세요.',
      'Connection failed': '서버에 연결할 수 없습니다.',
      'Timeout': '요청 시간이 초과되었습니다.',
    };

    // 정확히 일치하는 메시지가 있는지 확인
    if (translations.containsKey(message)) {
      return translations[message]!;
    }

    // 부분 일치하는 메시지 찾기
    for (final entry in translations.entries) {
      if (message.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // 특정 패턴 처리
    if (message.contains('서비스 출시 초기로 사용자 수가 제한')) {
      return message; // 이미 한국어인 메시지는 그대로 반환
    }

    // 비밀번호 관련 에러 (이미 한국어로 된 것들)
    if (message.contains('비밀번호') || message.contains('최소') || message.contains('특수문자')) {
      return message;
    }

    return message; // 번역되지 않은 메시지는 그대로 반환
  }

  // 네트워크 예외 처리를 위한 래퍼 메서드들
  static Future<http.Response> _handleRequest(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('요청 시간이 초과되었습니다.'),
      );
    } catch (e) {
      if (e.toString().contains('요청 시간이 초과')) {
        rethrow;
      }
      
      // 플랫폼별 에러 처리
      if (kIsWeb) {
        // 웹에서의 네트워크 에러 처리
        if (e.toString().contains('Failed to fetch') || 
            e.toString().contains('NetworkError') ||
            e.toString().contains('CORS')) {
          throw Exception('네트워크 연결을 확인해주세요.');
        } else if (e.toString().contains('timeout') || 
                   e.toString().contains('TimeoutException')) {
          throw Exception('요청 시간이 초과되었습니다.');
        }
      } else {
        // 모바일/데스크톱에서의 네트워크 에러 처리
        try {
          if (e is SocketException) {
            throw Exception('네트워크 연결을 확인해주세요.');
          } else if (e is HttpException) {
            throw Exception('서버에 연결할 수 없습니다.');
          } else if (e is FormatException) {
            throw Exception('서버 응답을 처리할 수 없습니다.');
          }
        } catch (_) {
          // Platform-specific exception 처리 실패 시 일반 처리
        }
      }
      
      throw Exception('알 수 없는 오류가 발생했습니다: ${e.toString()}');
    }
  }
} 