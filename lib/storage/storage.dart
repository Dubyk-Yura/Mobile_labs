abstract class Storage {
  Future<void> registerUser(String email, String password, String login);

  Future<void> loginUser(String email, String password);

  Future<void> logout();

  Future<String?> getCurrentUserEmail();

  Future<bool> isLoggedIn();

  Future<String?> getCurrentUserLogin();

  Future<Map<String, dynamic>?> readTopicData(String email, String topic);

  Future<void> writeTopicData(
    String email,
    String topic,
    Map<String, dynamic> jsonData,
  );
}
