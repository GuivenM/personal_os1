import '../utils/json_parsing.dart';

class User {
  const User({
    required this.id,
    required this.username,
    this.createdAt,
    this.visionText,
  });

  final int id;
  final String username;
  final String? createdAt;
  final String? visionText;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: asInt(json['id']),
      username: json['username'] as String,
      createdAt: json['created_at'] as String?,
      visionText: json['vision_text'] as String?,
    );
  }
}
