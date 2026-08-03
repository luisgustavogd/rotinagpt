import '../../domain/health/health_gateway.dart';

/// Implementação vazia usada no MVP. Fase 2 substitui por uma implementação
/// real usando o pacote `health` (HealthKit no iOS, Health Connect no
/// Android), sem exigir mudanças em `domain` ou `features`.
class NoOpHealthGateway implements HealthGateway {
  const NoOpHealthGateway();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> requestAuthorization() async => false;

  @override
  Future<int?> readStepsToday() async => null;
}
