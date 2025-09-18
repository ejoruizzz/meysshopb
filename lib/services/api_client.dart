import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error genérico para envolver respuestas HTTP no exitosas.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic data;

  ApiException(this.statusCode, this.message, {this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Cliente HTTP centralizado con soporte para tokens y refresh automático.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  String? _accessToken;
  String? _refreshToken;
  Completer<void>? _refreshCompleter;
  bool _closed = false;

  /// Devuelve el access token actual (si existe).
  String? get accessToken => _accessToken;

  /// Devuelve el refresh token actual (si existe).
  String? get refreshToken => _refreshToken;

  /// Permite actualizar ambos tokens después de login/refresh.
  void updateTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  /// Limpia las credenciales almacenadas.
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Cierra el cliente HTTP interno.
  void close() {
    if (_closed) return;
    _closed = true;
    _httpClient.close();
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      'GET',
      path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) {
    return _request(
      'DELETE',
      path,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  /// Permite forzar un refresh manual de tokens.
  Future<String?> refreshTokens() async {
    final success = await _attemptTokenRefresh();
    return success ? _accessToken : null;
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool retryOnUnauthorized = true,
  }) async {
    if (_closed) {
      throw StateError('ApiClient has been closed');
    }

    final request = http.Request(method, _resolveUri(path, queryParameters));
    request.headers.addAll(_buildHeaders(body: body, extraHeaders: headers));
    if (body != null) {
      request.body = _encodeBody(body);
    }

    http.Response response = await http.Response.fromStream(await _httpClient.send(request));

    if (response.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        return _request(
          method,
          path,
          body: body,
          queryParameters: queryParameters,
          headers: headers,
          retryOnUnauthorized: false,
        );
      }
    }

    return _parseResponse(response);
  }

  Map<String, String> _buildHeaders({
    Object? body,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (body != null && body is! http.BaseRequest && body is! String) {
      headers['Content-Type'] = 'application/json';
    }
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_accessToken!}';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _resolveUri(String path, Map<String, dynamic>? queryParameters) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final qp = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      qp[key] = value.toString();
    });
    return uri.replace(queryParameters: qp.isEmpty ? null : qp);
  }

  String _encodeBody(Object body) {
    if (body is String) return body;
    if (body is List || body is Map) return jsonEncode(body);
    return jsonEncode(body);
  }

  dynamic _parseResponse(http.Response response) {
    final status = response.statusCode;
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (status < 200 || status >= 300) {
      final message = _errorMessageFrom(data) ?? 'HTTP $status';
      throw ApiException(status, message, data: data);
    }

    return data;
  }

  String? _errorMessageFrom(dynamic data) {
    if (data is Map<String, dynamic>) {
      final error = data['error'] ?? data['message'];
      if (error is String) return error;
    }
    return null;
  }

  Future<bool> _attemptTokenRefresh() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) {
      return false;
    }

    if (_refreshCompleter != null) {
      try {
        await _refreshCompleter!.future;
        return _accessToken != null;
      } catch (_) {
        return false;
      }
    }

    if (_closed) return false;

    final completer = Completer<void>();
    _refreshCompleter = completer;

    try {
      final response = await _httpClient.post(
        _resolveUri('/api/auth/refresh', null),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refresh}),
      );

      final data = _parseResponse(response);
      if (data is! Map<String, dynamic>) {
        throw ApiException(response.statusCode, 'Respuesta inválida del refresh', data: data);
      }

      final newAccess = data['access'] as String?;
      final newRefresh = data['refresh'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        throw ApiException(response.statusCode, 'Refresh sin access token', data: data);
      }

      _accessToken = newAccess;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        _refreshToken = newRefresh;
      }

      completer.complete();
      return true;
    } catch (e) {
      clearTokens();
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      return false;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }
}