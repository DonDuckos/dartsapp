import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Web-Client-ID aus android/app/google-services.json (client_type 3, "Web
/// client (auto created by Google Service)") — Google Sign-In braucht sie als
/// serverClientId, damit das ausgestellte ID-Token von Firebase Auth
/// akzeptiert wird. Kein Geheimnis, nur eine öffentliche Client-Kennung.
const _googleWebClientId = '610197435316-j6og5m1aa0ug1s7hv2qkdhar0scatl1m.apps.googleusercontent.com';

final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _googleWebClientId);
    _initialized = true;
  }

  Future<void> signInWithGoogle() async {
    await _ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
