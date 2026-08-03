import 'dart:developer' as developer;

/// RNF-010 — registra erros técnicos localmente (console/DevTools) sem
/// gravar conteúdo sensível (nada de dados de refeição, peso, medicação ou
/// sintomas nos logs — só a mensagem técnica do erro).
class AppLogger {
  const AppLogger();

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: 'rotinagpt',
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }

  void info(String message) {
    developer.log(message, name: 'rotinagpt');
  }
}
