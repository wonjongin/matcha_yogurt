import 'package:flutter/material.dart';

class ErrorUtils {
  // Exception에서 깔끔한 메시지 추출
  static String getCleanErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    
    // 'Exception: ' 접두사 제거
    if (errorMessage.startsWith('Exception: ')) {
      errorMessage = errorMessage.substring(11);
    }
    
    // 기타 불필요한 접두사들 제거
    const prefixesToRemove = [
      'SocketException: ',
      'HttpException: ',
      'FormatException: ',
      'TimeoutException: ',
    ];
    
    for (final prefix in prefixesToRemove) {
      if (errorMessage.startsWith(prefix)) {
        errorMessage = errorMessage.substring(prefix.length);
        break;
      }
    }
    
    return errorMessage;
  }

  // 에러를 사용자 친화적인 SnackBar로 표시
  static void showErrorSnackBar(BuildContext context, dynamic error, {Duration? duration}) {
    final message = getCleanErrorMessage(error);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: duration ?? const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: '닫기',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  // 성공 메시지 표시
  static void showSuccessSnackBar(BuildContext context, String message, {Duration? duration}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: duration ?? const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 에러 종류별 아이콘 반환
  static IconData getErrorIcon(dynamic error) {
    final message = getCleanErrorMessage(error).toLowerCase();
    
    if (message.contains('네트워크') || message.contains('연결')) {
      return Icons.wifi_off;
    } else if (message.contains('인증') || message.contains('로그인')) {
      return Icons.lock_outline;
    } else if (message.contains('권한')) {
      return Icons.security;
    } else if (message.contains('시간') || message.contains('timeout')) {
      return Icons.access_time;
    } else {
      return Icons.error_outline;
    }
  }

  // 에러 다이얼로그 표시 (중요한 에러용)
  static void showErrorDialog(BuildContext context, dynamic error, {String? title}) {
    final message = getCleanErrorMessage(error);
    final icon = getErrorIcon(error);
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(icon, size: 48, color: Colors.red),
          title: Text(title ?? '오류가 발생했습니다'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
} 