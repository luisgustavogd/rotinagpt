import '../../domain/security/app_lock_gateway.dart';

/// Implementação vazia usada no MVP. Fase 2 substitui por uma implementação
/// real com `local_auth` (Face ID/Touch ID/impressão digital) como bloqueio
/// de app complementar ao login já existente.
class NoOpAppLockGateway implements AppLockGateway {
  const NoOpAppLockGateway();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<bool> isEnabled() async => false;

  @override
  Future<void> setEnabled(bool enabled) async {}

  @override
  Future<bool> authenticate() async => true;
}
