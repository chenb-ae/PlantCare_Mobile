import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? userId;
  String? name;
  String? email;
  String? createdAt;
  String? avatarPath;

  bool get isLoggedIn => userId != null && userId!.isNotEmpty;

  String get currentUserId => (userId != null && userId!.isNotEmpty) ? userId! : 'demo_user';

  void setUser({
    required String userId,
    required String name,
    required String email,
    String? createdAt,
    String? avatarPath,
  }) {
    this.userId = userId;
    this.name = name;
    this.email = email;
    this.createdAt = createdAt;
    if (avatarPath != null) this.avatarPath = avatarPath;
    saveToPrefs();
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) await prefs.setString('user_id', userId!);
    if (name != null) await prefs.setString('user_name', name!);
    if (email != null) await prefs.setString('user_email', email!);
    if (createdAt != null) await prefs.setString('user_created_at', createdAt!);
    if (avatarPath != null) await prefs.setString('user_avatar_path', avatarPath!);
  }

  Future<bool> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('user_id');
    if (savedId != null && savedId.isNotEmpty) {
      userId = savedId;
      name = prefs.getString('user_name');
      email = prefs.getString('user_email');
      createdAt = prefs.getString('user_created_at');
      avatarPath = prefs.getString('user_avatar_path');
      return true;
    }
    return false;
  }

  Future<void> clear() async {
    userId = null;
    name = null;
    email = null;
    createdAt = null;
    avatarPath = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
