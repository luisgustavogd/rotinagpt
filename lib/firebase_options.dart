// GERADO AUTOMATICAMENTE por `flutterfire configure`.
//
// As credenciais do Android correspondem ao projeto Firebase real
// "Saude em foco" (saude-em-foco-c49c3). O bloco iOS ainda é placeholder —
// será preenchido quando a Fase 2 (Apple Developer Program) rodar
// `flutterfire configure` novamente com a plataforma ios incluída.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions não configurado para web. Rode `flutterfire configure`.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions não suporta esta plataforma. Rode `flutterfire configure`.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDPy1wn5WY0HBe_hPV72Rt_-gOkLeREOmM',
    appId: '1:93551519798:android:b8243f206f90d1315d1097',
    messagingSenderId: '93551519798',
    projectId: 'saude-em-foco-c49c3',
    storageBucket: 'saude-em-foco-c49c3.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    iosBundleId: 'com.luisgustavogd.rotinagpt',
  );
}
