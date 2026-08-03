import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Camada extra de segurança contra clientes não oficiais acessando o
  // Firestore (ver seção 3 do plano/README). Em desenvolvimento, use o
  // provider de debug do App Check antes de gerar builds de produção.
  await FirebaseAppCheck.instance.activate();

  runApp(const ProviderScope(child: RotinaGptApp()));
}
