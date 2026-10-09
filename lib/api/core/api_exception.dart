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
      
      final rawMessage = data['message']?.toString() ?? '';
      if (rawMessage.isNotEmpty) {
        message = rawMessage;
      }
      
      else if (data.containsKey('data') && data['data'] is Map) {
        final nested = data['data'] as Map;
        final nestedMsg = nested['message']?.toString() ?? '';
        if (nestedMsg.isNotEmpty) message = nestedMsg;
      }

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
      if (data.contains('Request body too large') || data.contains('Multipart body length limit') || statusCode == 413) {
        message = 'حجم فایل انتخاب شده بیشتر از سقف مجاز برای آپلود است.';
      } else {
        message = data;
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message = 'مهلت اتصال به سرور به پایان رسید. لطفاً اینترنت خود را بررسی کنید.';
          break;
        case DioExceptionType.sendTimeout:
          message = 'زمان بارگذاری و ارسال فایل به پایان رسید. لطفاً اتصال اینترنت خود را بررسی کنید.';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'پاسخی از سرور در مهلت مقرر دریافت نشد. لطفاً دوباره تلاش کنید.';
          break;
        case DioExceptionType.badResponse:
          if (statusCode == 413) {
            message = 'حجم فایل ارسالی بیشتر از حد مجاز است (کد خطای ۴۱۳).';
          } else if (statusCode == 408) {
            message = 'زمان درخواست به پایان رسید (کد خطای ۴۰۸).';
          } else {
            message = 'پاسخ نامعتبر از سرور دریافت شد (کد خطای $statusCode).';
          }
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
