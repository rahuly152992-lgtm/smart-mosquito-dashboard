import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String _name = 'Dr. Alok Verma';
  String _email = 'alok.verma@health.gov.in';
  String _role = 'Field Officer';
  bool _isLoggedIn = true;

  String get name => _name;
  String get email => _email;
  String get role => _role;
  bool get isLoggedIn => _isLoggedIn;

  bool login(String email, String password) {
    if (email.trim().isEmpty || password.isEmpty) return false;
    _email = email.trim();
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  void updateProfile({required String name, required String email, required String role}) {
    if (name.trim().isEmpty || email.trim().isEmpty || role.trim().isEmpty) return;
    _name = name.trim();
    _email = email.trim();
    _role = role.trim();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}