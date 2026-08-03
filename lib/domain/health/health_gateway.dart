/// Ponto de extensão Fase 2 (RF-055): HealthKit (iOS) / Health Connect
/// (Android) via o pacote `health`. Não implementado no MVP — a interface
/// existe só para que a Fase 2 não exija retrabalho nas camadas de domínio
/// ou apresentação. Implementação atual: `data/health/no_op_health_gateway.dart`.
abstract class HealthGateway {
  Future<bool> isAvailable();

  Future<bool> requestAuthorization();

  Future<int?> readStepsToday();
}
