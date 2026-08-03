/// Erro de aplicação com uma mensagem já pronta para exibir ao usuário (em
/// português, sem jargão técnico) — nunca expõe stack trace ou detalhes de
/// infraestrutura na UI (RNF-010).
class AppFailure {
  const AppFailure(this.userMessage, {this.cause});

  final String userMessage;
  final Object? cause;

  @override
  String toString() => userMessage;
}
