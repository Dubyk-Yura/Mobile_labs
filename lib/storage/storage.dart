abstract class Storage {
  Future<void> registerUser(String email, String password, String login);

  Future<void> loginUser(String email, String password);

  Future<void> logout();

  Future<String?> getCurrentUserEmail();

  Future<bool> isLoggedIn();

  Future<String?> getCurrentUserLogin();

  Future<String?> read(String email);

  Future<void> write(String email, String data);
}
