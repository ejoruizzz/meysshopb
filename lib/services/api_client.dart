import 'dart:convert';

import 'package:http/http.dart' as http;

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
