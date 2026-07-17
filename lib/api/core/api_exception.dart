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
      // Check for ErrorResponse or ValidationErrorResponse
      if (data.containsKey('message') && data['message'] != null) {
        message = data['message'].toString();
      }

      if (data.containsKey('errors') && data['errors'] is Map) {
        final rawErrors = data['errors'] as Map<dynamic, dynamic>;
        validationErrors = rawErrors.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
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
