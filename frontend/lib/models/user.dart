class User {
  final int id;
  final String username;
  final String email;
  final String displayName;
  final String? googleId;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.googleId,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      displayName: json['display_name'] ?? '',
      googleId: json['google_id'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'google_id': googleId,
      'avatar_url': avatarUrl,
    };
  }
}
