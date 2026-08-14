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

  /// Für Nutzer ohne eigenen Google-Account: Anmeldung mit vorab vergebenen
  /// Zugangsdaten statt Google Sign-In. Der Benutzername wird intern auf eine
  /// Fake-E-Mail gemappt (Firebase Auth verlangt für den Email/Password-
  /// Provider ein E-Mail-Format, auch wenn nie eine Mail dorthin geht).
  Future<void> signInWithUsername(String username, String password) async {
    final email = username.contains('@') ? username.trim() : '${username.trim()}@dartsapp.app';
    await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
