import 'package:flutter/foundation.dart';

import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isBusy => _busy;
  String? get error => _error;

  /// Recupera la sesión guardada. [minDuration] mantiene visible la pantalla
  /// de bienvenida aunque la lectura sea instantánea.
  Future<void> restore({Duration minDuration = Duration.zero}) async {
    final (user, _) = await (_repository.restoreSession(), Future<void>.delayed(minDuration)).wait;
    _user = user;
    _status = user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) =>
      _authenticate(() => _repository.signIn(email: email, password: password));

  Future<bool> register({required String name, required String email, required String password}) =>
      _authenticate(() => _repository.register(name: name, email: email, password: password));

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> updateProfile(AppUser updated) async {
    _user = await _repository.updateProfile(updated);
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AppUser> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _user = await action();
      _status = AuthStatus.signedIn;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
