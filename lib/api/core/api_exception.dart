import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, String>? validationErrors;
  final dynamic originalError;

  ApiException({
    this.statusCode,
    required this.message,
    this.validationErrors,
    this.originalError,
  });

  factory ApiException.fromDioError(DioException error) {
    int? statusCode = error.response?.statusCode;
    String message = 'خطایی در ارتباط با سرور رخ داده است.';
    Map<String, String>? validationErrors;

    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      // Top-level 'message' field (ApiResult envelope from backend)
      final rawMessage = data['message']?.toString() ?? '';
      if (rawMessage.isNotEmpty) {
        message = rawMessage;
      }
      // Nested data map may also have message
      else if (data.containsKey('data') && data['data'] is Map) {
        final nested = data['data'] as Map;
        final nestedMsg = nested['message']?.toString() ?? '';
        if (nestedMsg.isNotEmpty) message = nestedMsg;
      }

      // If message is a JSON object (from exception middleware), parse it
      if (message.startsWith('{')) {
        try {
          final exMatch = RegExp(r'"Exception"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(message);
          if (exMatch != null) {
            message = exMatch.group(1)?.replaceAll(r'\"', '"') ?? message;
          }
          final innerMatch = RegExp(r'"InnerException"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(message);
          if (innerMatch != null) {
            final inner = innerMatch.group(1)?.replaceAll(r'\"', '"') ?? '';
            if (inner.isNotEmpty) message += '\n↳ $inner';
          }
          final inner2Match = RegExp(r'"InnerInnerException"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(message);
          if (inner2Match != null) {
            final inner2 = inner2Match.group(1)?.replaceAll(r'\"', '"') ?? '';
            if (inner2.isNotEmpty) message += '\n↳↳ $inner2';
          }
        } catch (_) {}
      }

      if (data.containsKey('errors') && data['errors'] is Map) {
        final rawErrors = data['errors'] as Map<dynamic, dynamic>;
        validationErrors = rawErrors.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else {
      // General fallbacks based on DioExceptionType
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'اتصال به سرور برقرار نشد. لطفاً اینترنت خود را بررسی کنید.';
          break;
        case DioExceptionType.badResponse:
          message = 'پاسخ نامعتبر از سرور دریافت شد (کد خطای $statusCode).';
          break;
        case DioExceptionType.cancel:
          message = 'درخواست توسط کاربر لغو شد.';
          break;
        case DioExceptionType.connectionError:
          final details = error.error != null ? ' (${error.error})' : '';
          message = 'مشکل در برقراری ارتباط با شبکه سرور.$details';
          break;
        default:
          message = 'خطای غیرمنتظره‌ای رخ داده است.';
          break;
      }
    }

    return ApiException(
      statusCode: statusCode,
      message: message,
      validationErrors: validationErrors,
      originalError: error,
    );
  }

  @override
  String toString() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return '$message: ${validationErrors.toString()}';
    }
    return message;
  }
}
