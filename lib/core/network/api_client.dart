import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';

/// P1-3.1：统一 HTTP 客户端，connect 15s / receive 60s
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const _connectTimeout = Duration(seconds: 15);
  static const _receiveTimeout = Duration(seconds: 60);
  static const _retryDelays = [Duration(seconds: 1), Duration(seconds: 4), Duration(seconds: 15)];

  http.Client? _client;

  http.Client get client {
    _client ??= http.Client();
    return _client!;
  }

  void close() {
    _client?.close();
    _client = null;
  }

  /// 幂等 POST JSON，5xx/超时自动重试最多 3 次
  Future<Map<String, dynamic>> postJson({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
    bool retryOnFailure = true,
  }) async {
    Object? lastError;
    final attempts = retryOnFailure ? _retryDelays.length + 1 : 1;

    for (var i = 0; i < attempts; i++) {
      try {
        final response = await client
            .post(uri, headers: headers, body: jsonEncode(body))
            .timeout(_receiveTimeout);
        return _handleResponse(response);
      } on TimeoutException {
        lastError = const TimeoutApiException();
        if (i < attempts - 1) await Future<void>.delayed(_retryDelays[i]);
      } on ApiException catch (e) {
        if (e is ServerException && e.statusCode >= 500 && i < attempts - 1) {
          lastError = e;
          await Future<void>.delayed(_retryDelays[i]);
          continue;
        }
        rethrow;
      } on http.ClientException catch (e) {
        lastError = NetworkException(e.message);
        if (i < attempts - 1) await Future<void>.delayed(_retryDelays[i]);
      }
    }
    throw lastError ?? const NetworkException();
  }

  /// POST JSON，不抛非 2xx，始终尝试解析 body（IMA 401 仍含业务码）
  Future<Map<String, dynamic>> postJsonLenient({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_receiveTimeout);
      final decoded = _tryDecodeBody(response);
      if (decoded != null) return decoded;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ServerException(response.statusCode, 'HTTP ${response.statusCode}');
      }
      throw const ParseException('响应解析失败');
    } on TimeoutException {
      throw const TimeoutApiException();
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    }
  }

  /// 流式 POST，返回原始 ResponseStream
  Future<http.StreamedResponse> postStream({
    required Uri uri,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async {
    final request = http.Request('POST', uri);
    request.headers.addAll(headers);
    request.body = jsonEncode(body);
    return client.send(request).timeout(_receiveTimeout);
  }

  Map<String, dynamic>? _tryDecodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final status = response.statusCode;
    if (status == 401) throw const UnauthorizedException();
    if (status == 402) throw const InsufficientBalanceException();
    if (status == 429) throw const RateLimitException();
    if (status >= 500) {
      throw ServerException(status, '服务器错误 ($status)');
    }
    if (status < 200 || status >= 300) {
      throw ServerException(status, '请求失败 ($status)');
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      throw const ParseException('响应格式不是 JSON 对象');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const ParseException();
    }
  }
}
