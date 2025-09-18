
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

class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUri = _normalizeBase(baseUrl),
        _http = httpClient ?? http.Client();

  final Uri _baseUri;
  final http.Client _http;

  static Uri _normalizeBase(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    if (uri.path.isEmpty || uri.path == '/') {
      return uri.replace(path: '');
    }
    return uri;
  }

  Uri _resolve(String path, [Map<String, dynamic>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = _baseUri.resolve(normalizedPath);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final qp = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      qp[key] = value.toString();
    });
    return uri.replace(queryParameters: qp);
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    final base = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (headers != null) {
      base.addAll(headers);
    }
    return base;
  }

  dynamic _decodeBody(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return null;
    }
    final text = utf8.decode(response.bodyBytes);
    if (text.isEmpty) return null;
    return jsonDecode(text);
  }

  Never _throwError(http.Response response) {
    throw ApiException(
      statusCode: response.statusCode,
      message: response.reasonPhrase ?? 'Error HTTP',
      responseBody: response.body.isEmpty ? null : response.body,
    );

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

  }) async {
    final response = await _http.get(
      _resolve(path, queryParameters),
      headers: _mergeHeaders(headers),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
    return _decodeBody(response);

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

  }) async {
    final response = await _http.post(
      _resolve(path, queryParameters),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
    return _decodeBody(response);

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

  }) async {
    final response = await _http.put(
      _resolve(path, queryParameters),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
    return _decodeBody(response);

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

  }) async {
    final response = await _http.patch(
      _resolve(path, queryParameters),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
    return _decodeBody(response);
  }

  Future<void> delete(

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
    bool hasPrefix(List<String> segments, List<String> prefix) {
      if (prefix.isEmpty || prefix.length > segments.length) {
        return false;
      }
      for (var i = 0; i < prefix.length; i++) {
        if (segments[i] != prefix[i]) {
          return false;
        }
      }
      return true;
    }

    final baseUri = Uri.parse(baseUrl);
    final mergedQuery = <String, String>{};
    Uri uri;

    final trimmedPath = path.trim();
    if (trimmedPath.isEmpty) {
      uri = baseUri;
      mergedQuery.addAll(baseUri.queryParameters);
    } else {
      final parsedPath = Uri.parse(trimmedPath);
      mergedQuery.addAll(parsedPath.queryParameters);

      if (parsedPath.hasScheme) {
        uri = parsedPath;
      } else {
        final baseSegments = baseUri.pathSegments.where((segment) => segment.isNotEmpty).toList();
        final pathSegments = parsedPath.pathSegments.where((segment) => segment.isNotEmpty).toList();
        final combinedSegments = <String>[];

        if (trimmedPath.startsWith('/')) {
          combinedSegments.addAll(pathSegments);
        } else if (baseSegments.isEmpty || hasPrefix(pathSegments, baseSegments)) {
          combinedSegments.addAll(pathSegments);
        } else {
          combinedSegments
            ..addAll(baseSegments)
            ..addAll(pathSegments);
        }

        final fragment = parsedPath.fragment.isEmpty ? null : parsedPath.fragment;
        uri = baseUri.replace(
          pathSegments: combinedSegments,
          queryParameters: null,
          fragment: fragment,
        );
      }
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      queryParameters.forEach((key, value) {
        if (value == null) return;
        mergedQuery[key] = value.toString();
      });
    }

    return mergedQuery.isEmpty
        ? uri.replace(queryParameters: null)
        : uri.replace(queryParameters: mergedQuery);
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

  }) async {
    final response = await _http.delete(
      _resolve(path, queryParameters),
      headers: _mergeHeaders(headers),
      body: _encodeBody(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwError(response);
    }
  }

  void close() => _http.close();

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
    return jsonEncode(body);
  }
}

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.responseBody,
  });

  final int statusCode;
  final String message;
  final String? responseBody;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException($statusCode): $message');
    if (responseBody != null && responseBody!.isNotEmpty) {
      buffer.write(' -> ');
      buffer.write(responseBody);
    }
    return buffer.toString();
  }
}

extension ApiClientTestAccess on ApiClient {
  Uri resolveUriForTest(String path, [Map<String, dynamic>? queryParameters]) {
    return _resolveUri(path, queryParameters);
  }
}

