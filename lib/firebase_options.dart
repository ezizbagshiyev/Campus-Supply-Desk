// Generate real Android project options with flutterfire configure --platforms=android.
import 'package:firebase_core/firebase_core.dart';
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Run flutterfire configure --platforms=android for your Firebase project.');
}
