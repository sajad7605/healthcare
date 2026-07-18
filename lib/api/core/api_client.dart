import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  String _baseUrl;
  String? _authToken;

  ApiClient({
   String baseUrl = 'https://h.ghahremansalamat.ir',
    //String baseUrl = 'http://127.0.0.1:5158',
    String? token,
  })  : _baseUrl = baseUrl,
        _authToken = token {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        // Allow self-signed or development SSL certificates on native devices
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null && _authToken!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.data != null) {
            response.data = unwrapResponse(response.data);
          }
          return handler.next(response);
        },
      ),
    );
  }

  /// Helper to unwrap ApiResult envelope from ASP.NET Core BaseController responses.
  static dynamic unwrapResponse(dynamic data) {
    if (data is Map<String, dynamic> || data is Map) {
      final map = data as Map;
      if (map.containsKey('isSuccess') && map.containsKey('data')) {
        return map['data'] ?? map;
      }
      if (map.containsKey('data') && map['data'] is List) {
        return map['data'];
      }
    }
    return data;
  }

  /// Update the base URL of the client dynamically.
  void setBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  String get baseUrl => _baseUrl;

  /// Update the authentication token dynamically.
  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  /// HTTP GET wrapper
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// HTTP POST wrapper
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// HTTP PUT wrapper
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// HTTP DELETE wrapper
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// HTTP POST Multipart wrapper (for files)
  Future<Response<T>> postMultipart<T>(
    String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final formDataMap = <String, dynamic>{};
      
      for (final entry in data.entries) {
        if (entry.value is File) {
          final file = entry.value as File;
          final fileName = file.path.split('/').last;
          formDataMap[entry.key] = await MultipartFile.fromFile(
            file.path,
            filename: fileName,
          );
        } else if (entry.value is List<File>) {
          final files = entry.value as List<File>;
          final multipartFiles = <MultipartFile>[];
          for (final file in files) {
            final fileName = file.path.split('/').last;
            multipartFiles.add(
              await MultipartFile.fromFile(file.path, filename: fileName),
            );
          }
          formDataMap[entry.key] = multipartFiles;
        } else {
          formDataMap[entry.key] = entry.value;
        }
      }

      final formData = FormData.fromMap(formDataMap);

      final requestOptions = options ?? Options();
      requestOptions.contentType = 'multipart/form-data';

      return await _dio.post<T>(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
