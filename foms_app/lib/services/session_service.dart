import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _roleKey = 'session_role';
  static const String _nameKey = 'session_name';
  static const String _phoneKey = 'session_phone';
  static const String _locationKey = 'session_location';
  static const String _usernameKey = 'session_username';

  static Future<void> saveUser(
    Map<String, dynamic> user,
    String role,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.trim().toLowerCase());
    await prefs.setString(_nameKey, (user['name'] ?? '').toString());
    await prefs.setString(_phoneKey, (user['phone'] ?? '').toString());
    await prefs.setString(_locationKey, (user['location'] ?? '').toString());
    await prefs.setString(_usernameKey, (user['username'] ?? '').toString());
  }

  static Future<Map<String, String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return <String, String>{
      'role': prefs.getString(_roleKey) ?? '',
      'name': prefs.getString(_nameKey) ?? '',
      'phone': prefs.getString(_phoneKey) ?? '',
      'location': prefs.getString(_locationKey) ?? '',
      'username': prefs.getString(_usernameKey) ?? '',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roleKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_locationKey);
    await prefs.remove(_usernameKey);
  }
}
