import 'dart:convert';
import '../services/api_service.dart';
import '../models/models.dart';

class AuthResponse {
  final String accessToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthService {
  // 회원가입 (이메일 인증 필요)
  static Future<String> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
      });

      final data = ApiService.handleResponse(response);
      return data['message'] as String;
    } catch (e) {
      // ApiService에서 이미 한국어 메시지로 변환되므로 그대로 전달
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // 'Exception: ' 제거
      }
      throw Exception(errorMessage);
    }
  }

  // 로그인
  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = ApiService.handleResponse(response);
      final authResponse = AuthResponse.fromJson(data);
      
      // JWT 토큰 저장
      await ApiService.saveToken(authResponse.accessToken);
      
      return authResponse;
    } catch (e) {
      // ApiService에서 이미 한국어 메시지로 변환되므로 그대로 전달
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11); // 'Exception: ' 제거
      }
      throw Exception(errorMessage);
    }
  }

  // 현재 사용자 정보 조회
  static Future<User> getCurrentUser() async {
    try {
      final response = await ApiService.get('/auth/me', requireAuth: true);
      final data = ApiService.handleResponse(response);
      return User.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      throw Exception(errorMessage);
    }
  }

  // 로그아웃
  static Future<void> logout() async {
    await ApiService.deleteToken();
  }

  // 토큰 유효성 검사
  static Future<bool> isLoggedIn() async {
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      await logout(); // 토큰이 무효하면 삭제
      return false;
    }
  }

  // 토큰 존재 여부만 확인 (네트워크 없이)
  static Future<bool> hasToken() async {
    final token = await ApiService.getToken();
    return token != null;
  }

  // 이메일 인증
  static Future<AuthResponse> verifyEmail(String token) async {
    try {
      final response = await ApiService.post('/auth/verify-email', {
        'token': token,
      });

      final data = ApiService.handleResponse(response);
      final authResponse = AuthResponse.fromJson(data);
      
      // JWT 토큰 저장
      await ApiService.saveToken(authResponse.accessToken);
      
      return authResponse;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      throw Exception(errorMessage);
    }
  }

  // 인증 이메일 재발송
  static Future<String> resendVerificationEmail(String email) async {
    try {
      final response = await ApiService.post('/auth/resend-verification', {
        'email': email,
      });

      final data = ApiService.handleResponse(response);      
      return data['message'] as String;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      throw Exception(errorMessage);
    }
  }
} 