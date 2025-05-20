import 'dart:convert';

import 'package:mobile_labs/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageImpl implements Storage {
  static const _usersKey = 'users';
  static const _currentUserKey = 'current_user';

  @override
  Future<void> registerUser(String email, String password, String login) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final users = usersJson == null
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(usersJson) as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              Map<String, dynamic>.from(value as Map),
            ),
          );

    if (users.containsKey(email)) {
      throw Exception('User already exists');
    }

    users[email] = {
      'password': password,
      'login': login,
    };
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_currentUserKey, email);
  }

  @override
  Future<void> loginUser(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final users = usersJson == null
        ? <String, Map<String, dynamic>>{}
        : (jsonDecode(usersJson) as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              Map<String, dynamic>.from(value as Map),
            ),
          );

    if (!users.containsKey(email)) {
      throw Exception('User does not exist');
    }

    final storedPassword = users[email]?['password'];
    if (storedPassword != password) {
      throw Exception('Incorrect password');
    }

    await prefs.setString(_currentUserKey, email);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  @override
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_currentUserKey);
  }

  @override
  Future<String?> getCurrentUserLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    final currentEmail = prefs.getString(_currentUserKey);

    if (usersJson == null || currentEmail == null) return null;

    final users = jsonDecode(usersJson) as Map<String, dynamic>;
    final userData = users[currentEmail] as Map<String, dynamic>?;

    return userData?['login'] as String?;
  }

  @override
  Future<void> writeTopicData(
    String email,
    String topic,
    Map<String, dynamic> jsonData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sensor_data_${email}_$topic';
    final jsonString = jsonEncode(jsonData);
    await prefs.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> readTopicData(
    String email,
    String topic,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'sensor_data_${email}_$topic';
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }
}
