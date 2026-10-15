import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/storage_service.dart';

/// Exception levée pour toute erreur renvoyée par l'API ou le réseau.
///
/// Le serveur répond en cas d'erreur avec :
/// `{ "error": "message" }` ou `{ "error": "message", "details": [...] }`
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final List<String>? details;

  @override
  String toString() {
    if (details != null && details!.isNotEmpty) {
      return '$message (${details!.join(', ')})';
    }
    return message;
  }
}

/// Client HTTP centralisé.
///
/// - Injecte automatiquement `Authorization: Bearer <token>` sur chaque
///   requête si un token est présent.
/// - Décode les réponses JSON et les erreurs `{ "error": ... }`.
/// - Sur un 401, supprime le token local et notifie [onUnauthorized]
///   (branché par [AuthService] pour rediriger vers l'écran de login).
class ApiClient {
  ApiClient({
    required StorageService storageService,
    this.baseUrl = 'https://test.greentechnos.com/api',
    http.Client? httpClient,
  })  : _storage = storageService,
        _http = httpClient ?? http.Client();

  final String baseUrl;
  final StorageService _storage;
  final http.Client _http;

  /// Appelé lorsque le serveur renvoie 401 : le token est déjà supprimé
  /// à ce stade, à charge de l'appelant (AuthService) de mettre à jour
  /// l'état d'authentification et de rediriger vers /login.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final cleanQuery = query?.map((k, v) => MapEntry(k, v?.toString()))
      ?..removeWhere((k, v) => v == null);
    return Uri.parse('$baseUrl$normalized').replace(
      queryParameters: (cleanQuery == null || cleanQuery.isEmpty)
          ? null
          : cleanQuery.cast<String, String>(),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await _storage.readToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _send('GET', _uri(path, query));
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _send('POST', _uri(path), body: body);
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _send('PUT', _uri(path), body: body);
  }

  Future<dynamic> delete(String path, {Object? body}) {
    return _send('DELETE', _uri(path), body: body);
  }

  Future<dynamic> _send(String method, Uri uri, {Object? body}) async {
    final headers = await _headers();
    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await _http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'PUT':
          response = await _http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        case 'DELETE':
          response = await _http.delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
          break;
        default:
          throw ApiException('Méthode HTTP non supportée: $method');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erreur réseau : impossible de contacter le serveur.');
    }

    return _handleResponse(response);
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    final status = response.statusCode;
    final bodyText = response.body.isEmpty ? null : response.body;

    dynamic decoded;
    if (bodyText != null) {
      try {
        decoded = jsonDecode(bodyText);
      } catch (_) {
        decoded = null;
      }
    }

    if (status == 401) {
      await _storage.deleteToken();
      onUnauthorized?.call();
      throw ApiException(
        (decoded is Map && decoded['error'] != null) ? decoded['error'].toString() : 'Session expirée, reconnecte-toi.',
        statusCode: 401,
      );
    }

    if (status < 200 || status >= 300) {
      final message = (decoded is Map && decoded['error'] != null)
          ? decoded['error'].toString()
          : 'Une erreur est survenue (code $status).';
      final details = (decoded is Map && decoded['details'] is List)
          ? List<String>.from(decoded['details'].map((e) => e.toString()))
          : null;
      throw ApiException(message, statusCode: status, details: details);
    }

    return decoded;
  }
}
