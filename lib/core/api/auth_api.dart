import '../api/api_client.dart';
import '../models/user_model.dart';

/// Result of a successful login/register call.
class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final User user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthResult> login({required String username, required String password}) async {
    final json = await _client.post('/auth/login', body: {
      'username': username,
      'password': password,
    });
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResult> register({required String username, required String password}) async {
    final json = await _client.post('/auth/register', body: {
      'username': username,
      'password': password,
    });
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post('/auth/logout');
  }

  /// POST /auth/refresh — swaps a still-valid token for a fresh one
  /// (sliding expiration, called on every PIN / fingerprint unlock).
  Future<AuthResult> refresh() async {
    final json = await _client.post('/auth/refresh');
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<User> me() async {
    final json = await _client.get('/auth/me');
    return User.fromJson(json as Map<String, dynamic>);
  }
}
