import 'app_user.dart';

/// Autenticação federada (Sign in with Apple / Google) via Firebase Auth.
///
/// Não há e-mail/senha próprio nem pareamento por código: a conta serve
/// apenas para sincronizar os dados da mesma pessoa entre o iPhone e o
/// Android dela — não é uma conta compartilhável ou social.
abstract class AuthGateway {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signInWithApple();

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();
}
