/// Ponto de extensão Fase 2: bloqueio de app por biometria (Face ID/Touch
/// ID/impressão digital), complementar ao login do Firebase já existente —
/// não substitui a autenticação, só protege a reabertura do app já logado.
/// Não implementado no MVP. Implementação atual:
/// `data/security/no_op_app_lock_gateway.dart`.
abstract class AppLockGateway {
  Future<bool> isSupported();

  Future<bool> isEnabled();

  Future<void> setEnabled(bool enabled);

  Future<bool> authenticate();
}
