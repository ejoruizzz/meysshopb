import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Error genérico para envolver respuestas HTTP no exitosas.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message, {this.data});

  final int statusCode;
  final String message;
  final dynamic data;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException($statusCode): $message');
    if (data != null) {
      buffer.write(' -> ');
      buffer.write(data);
    }
    return buffer.toString();
  }
}

/// Cliente HTTP centralizado con soporte para tokens y refresh automático.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client() {
    final parsedBase = Uri.parse(baseUrl);
    _baseUri = _normalizeBase(parsedBase);
    _baseQueryParameters = Map.unmodifiable(parsedBase.queryParameters);
  }

  late final Uri _baseUri;
  late final Map<String, String> _baseQueryParameters;
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

    final resolvedUri = _resolveUri(path, queryParameters);
    final upperMethod = method.toUpperCase();
    Object? effectiveBody = body;
    if (effectiveBody is http.BaseRequest) {
      effectiveBody = await _BaseRequestPayload.from(effectiveBody);
    }

    final requestHeaders =
        _buildHeaders(body: effectiveBody, extraHeaders: headers);

    final http.BaseRequest request = await _createHttpRequest(
      upperMethod: upperMethod,
      resolvedUri: resolvedUri,
      body: effectiveBody,
      headers: requestHeaders,
    );

    final response =
        await http.Response.fromStream(await _httpClient.send(request));

    if (response.statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _attemptTokenRefresh();
      if (refreshed) {
        return _request(
          method,
          path,
          body: effectiveBody,
          queryParameters: queryParameters,
          headers: headers,
          retryOnUnauthorized: false,
        );
      }
    }

    return _parseResponse(response);
  }

  Future<http.BaseRequest> _createHttpRequest({
    required String upperMethod,
    required Uri resolvedUri,
    required Object? body,
    required Map<String, String> headers,
  }) async {
    if (body is _BaseRequestPayload) {
      final request = await body.instantiate(resolvedUri);
      if (request.method.toUpperCase() != upperMethod) {
        throw ArgumentError('Método del request no coincide con $upperMethod');
      }
      if (request.url != resolvedUri) {
        request.url = resolvedUri;
      }
      request.headers.addAll(headers);
      return request;
    }

    if (body is http.BaseRequest) {
      final payload = await _BaseRequestPayload.from(body);
      return _createHttpRequest(
        upperMethod: upperMethod,
        resolvedUri: resolvedUri,
        body: payload,
        headers: headers,
      );
    }

    final httpRequest = http.Request(upperMethod, resolvedUri);
    httpRequest.headers.addAll(headers);

    final encodedBody = _encodeBody(body);
    if (encodedBody != null) {
      httpRequest.body = encodedBody;
    }
    return httpRequest;
  }

  Map<String, String> _buildHeaders({
    Object? body,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (body != null &&
        body is! http.BaseRequest &&
        body is! _BaseRequestPayload &&
        body is! String) {
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

  Uri _resolveUri(String path, [Map<String, dynamic>? queryParameters]) {
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

    Map<String, String> mergedQuery = <String, String>{..._baseQueryParameters};
    final trimmedPath = path.trim();
    Uri uri = _baseUri;
    String? fragment;

    if (trimmedPath.isNotEmpty) {
      final parsedPath = Uri.parse(trimmedPath);
      fragment = parsedPath.fragment.isEmpty ? null : parsedPath.fragment;

      final bool hasDifferentAuthority = parsedPath.hasScheme &&
          (parsedPath.scheme != _baseUri.scheme ||
              parsedPath.host != _baseUri.host ||
              parsedPath.port != _baseUri.port);

      if (hasDifferentAuthority) {
        mergedQuery = <String, String>{...parsedPath.queryParameters};
        uri = parsedPath.replace(queryParameters: null, fragment: null);
      } else {
        mergedQuery.addAll(parsedPath.queryParameters);

        if (parsedPath.hasScheme) {
          uri = parsedPath.replace(queryParameters: null, fragment: null);
        } else {
          final baseSegments = _baseUri.pathSegments
              .where((segment) => segment.isNotEmpty)
              .toList();
          final pathSegments = parsedPath.pathSegments
              .where((segment) => segment.isNotEmpty)
              .toList();
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

          final normalizedSegments = <String>[];
          for (final segment in combinedSegments) {
            if (segment == '.' || segment.isEmpty) {
              continue;
            }
            if (segment == '..') {
              if (normalizedSegments.isNotEmpty) {
                normalizedSegments.removeLast();
              }
              continue;
            }
            normalizedSegments.add(segment);
          }

          uri = _baseUri.replace(
            pathSegments: normalizedSegments,
            queryParameters: null,
            fragment: null,
          );
        }
      }
    }

    if (queryParameters != null && queryParameters.isNotEmpty) {
      queryParameters.forEach((key, value) {
        if (value != null) {
          mergedQuery[key] = value.toString();
        }
      });
    }

    uri = mergedQuery.isEmpty
        ? uri.replace(queryParameters: null)
        : uri.replace(queryParameters: mergedQuery);

    if (fragment != null && fragment.isNotEmpty) {
      uri = uri.replace(fragment: fragment);
    }

    return uri;
  }

  static Uri _normalizeBase(Uri uri) {
    final normalizedPath = (uri.path.isEmpty || uri.path == '/')
        ? '/'
        : (uri.path.endsWith('/') ? uri.path : '${uri.path}/');

    return uri.replace(
      path: normalizedPath,
      queryParameters: null,
      fragment: null,
    );
  }

  String? _encodeBody(Object? body) {
    if (body == null) return null;
    if (body is String) return body;
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
        _resolveUri('/api/auth/refresh'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refresh}),
      );

      final data = _parseResponse(response);
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          response.statusCode,
          'Respuesta inválida del refresh',
          data: data,
        );
      }

      final newAccess = data['access'] as String?;
      final newRefresh = data['refresh'] as String?;

      if (newAccess == null || newAccess.isEmpty) {
        throw ApiException(
          response.statusCode,
          'Refresh sin access token',
          data: data,
        );
      }

      _accessToken = newAccess;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        _refreshToken = newRefresh;
      }

      completer.complete();
      return true;
    } catch (Object error, StackTrace stackTrace) {
      if (error is ApiException &&
          (error.statusCode == 400 || error.statusCode == 401)) {
        clearTokens();
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        return false;
      }

      developer.log(
        'Error refrescando tokens',
        name: 'ApiClient',
        error: error,
        stackTrace: stackTrace,
      );

      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
      rethrow;
    } finally {
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }
}

class _BaseRequestPayload {
  _BaseRequestPayload({
    required this.method,
    required this.headers,
    required this.followRedirects,
    required this.maxRedirects,
    required this.persistentConnection,
    required this.chunkedTransferEncoding,
    required this.contentLength,
    required Future<http.BaseRequest> Function(Uri uri) factory,
  }) : _factory = factory;

  final String method;
  final Map<String, String> headers;
  final bool followRedirects;
  final int maxRedirects;
  final bool persistentConnection;
  final bool chunkedTransferEncoding;
  final int? contentLength;
  final Future<http.BaseRequest> Function(Uri uri) _factory;

  Future<http.BaseRequest> instantiate(Uri uri) async {
    final request = await _factory(uri);
    request.followRedirects = followRedirects;
    request.maxRedirects = maxRedirects;
    request.persistentConnection = persistentConnection;
    request.chunkedTransferEncoding = chunkedTransferEncoding;
    if (contentLength != null) {
      request.contentLength = contentLength!;
    }
    if (request.url != uri) {
      request.url = uri;
    }
    request.headers.addAll(headers);
    return request;
  }

  static Future<_BaseRequestPayload> from(http.BaseRequest request) async {
    final headersCopy = Map<String, String>.from(request.headers);
    final followRedirects = request.followRedirects;
    final maxRedirects = request.maxRedirects;
    final persistentConnection = request.persistentConnection;
    final chunkedTransferEncoding = request.chunkedTransferEncoding;
    final int? originalContentLength = request.contentLength;

    if (request is http.MultipartRequest) {
      final fields = Map<String, String>.from(request.fields);
      final encoding = request.encoding;
      final files = <_MultipartFilePayload>[];
      for (final file in request.files) {
        files.add(await _MultipartFilePayload.fromMultipartFile(file));
      }

      return _BaseRequestPayload(
        method: request.method,
        headers: headersCopy,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        persistentConnection: persistentConnection,
        chunkedTransferEncoding: chunkedTransferEncoding,
        contentLength: originalContentLength,
        factory: (Uri uri) async {
          final clone = http.MultipartRequest(request.method, uri);
          clone.fields.addAll(fields);
          clone.encoding = encoding;
          for (final file in files) {
            clone.files.add(file.toMultipartFile());
          }
          return clone;
        },
      );
    }

    if (request is http.Request) {
      final encoding = request.encoding;
      final bodyBytes = request.bodyBytes;

      return _BaseRequestPayload(
        method: request.method,
        headers: headersCopy,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        persistentConnection: persistentConnection,
        chunkedTransferEncoding: chunkedTransferEncoding,
        contentLength: originalContentLength,
        factory: (Uri uri) async {
          final clone = http.Request(request.method, uri);
          clone.encoding = encoding;
          clone.bodyBytes = bodyBytes;
          return clone;
        },
      );
    }

    if (request is http.StreamedRequest) {
      final bytes = await http.ByteStream(request.finalize()).toBytes();
      final effectiveContentLength = originalContentLength ??
          (chunkedTransferEncoding ? null : bytes.length);

      return _BaseRequestPayload(
        method: request.method,
        headers: headersCopy,
        followRedirects: followRedirects,
        maxRedirects: maxRedirects,
        persistentConnection: persistentConnection,
        chunkedTransferEncoding: chunkedTransferEncoding,
        contentLength: effectiveContentLength,
        factory: (Uri uri) async {
          final clone = http.StreamedRequest(request.method, uri);
          if (effectiveContentLength != null) {
            clone.contentLength = effectiveContentLength;
          }
          clone.sink.add(bytes);
          await clone.sink.close();
          return clone;
        },
      );
    }

    throw UnsupportedError(
      'No es posible clonar automáticamente ${request.runtimeType}. '
      'Proporciona una nueva solicitud para cada reintento.',
    );
  }
}

class _MultipartFilePayload {
  _MultipartFilePayload({
    required this.field,
    required this.bytes,
    this.filename,
    this.contentType,
  });

  final String field;
  final List<int> bytes;
  final String? filename;
  final MediaType? contentType;

  http.MultipartFile toMultipartFile() {
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  static Future<_MultipartFilePayload> fromMultipartFile(
    http.MultipartFile file,
  ) async {
    final bytes = await http.ByteStream(file.finalize()).toBytes();
    return _MultipartFilePayload(
      field: file.field,
      bytes: bytes,
      filename: file.filename,
      contentType: file.contentType,
    );
  }
}

extension ApiClientTestAccess on ApiClient {
  Uri resolveUriForTest(String path, [Map<String, dynamic>? queryParameters]) {
    return _resolveUri(path, queryParameters);
  }
}
