# rotinagpt — Minha Rotina de Saúde

App pessoal de saúde/alimentação/rotina em Flutter (iOS + Android, um
codebase). Foco: proteína, peso, medicação informativa (ex.:
tirzepatida/Mounjaro), atividade física, exames.

**Este app não é um dispositivo médico.** Nunca diagnostica, nunca
prescreve, nunca sugere alterar dose de medicação. Sintomas e exames são
sempre autorrelatados e descritivos. Qualquer feature nova precisa respeitar
essa restrição — inclusive textos de ajuda/aviso.

## Stack

- **Flutter/Dart**, sem servidor próprio.
- **Firebase**: Firestore (offline nativo) + Firebase Auth. Auth só via
  Google Sign-In (Android) / Sign in with Apple (iOS, ainda não habilitado)
  — sem e-mail/senha próprio.
- **Riverpod** (DI/estado), **go_router** (navegação),
  **flutter_local_notifications** (lembretes locais, não usa FCM),
  **fl_chart**, **pdf**/**printing**/**archive**/**crypto** (backup).

## Arquitetura

```
lib/
├── app/       # app.dart, router.dart (guarda de auth via GoRouter), theme.dart
├── core/      # DI (Riverpod), erro, log, prefs locais
├── domain/    # Dart puro, sem Flutter/Firebase — entidades e regras de negócio
├── data/      # implementações: Firestore (remote/), auth, notificações, backup
└── features/  # telas por área: auth, onboarding, today, nutrition, progress,
               # routine, health, settings, more, shell
```

`domain/` nunca depende de `data/` nem de Flutter — só o contrário. Regra de
negócio deve ser testável sem subir Firebase nem um widget (`test/domain/`).
Todos os dados vivem no Firestore sob `/users/{uid}/...`; o cache offline
nativo do `cloud_firestore` já cobre "funciona sem internet, sincroniza ao
reconectar" — não crie uma segunda base local em paralelo.

Requisitos funcionais/regras de negócio são referenciados no código como
`RF-XXX`/`RN-XXX` em comentários (não há um documento único deles no repo;
`grep -rn "RN-\|RF-"` para achar onde uma regra específica está implementada
e testada).

## Convenções deste projeto

- **Campo calculado com sugestão editável**: quando um valor pode ser
  derivado de uma fórmula (ex.: meta de peso pelo IMC central, meta de
  proteína pelo nível de atividade), siga o padrão já usado em
  `lib/features/onboarding/onboarding_screen.dart` e
  `lib/features/settings/edit_profile_screen.dart`: sugerir/preencher o
  campo automaticamente, mostrar um helper text "valor calculado
  baseado em..." enquanto o valor não foi tocado manualmente, e esconder
  esse texto assim que o usuário edita o campo diretamente. Não sobrescrever
  silenciosamente um valor que o usuário já escolheu.
- **Histórico de metas é append-only** (RN-008, `goal_history_entry.dart`):
  nunca editar/apagar uma entrada de meta existente — sempre adicionar uma
  nova com `effectiveDate` mais recente.
- **Cuidado com nomes de classe colidindo entre camadas de domínio**: existe
  `ProteinCalculator` em `lib/domain/nutrition/` (soma proteína consumida no
  dia) e `ProteinTargetCalculator` em `lib/domain/profile/` (sugere meta de
  proteína a partir de peso + nível de atividade). São coisas diferentes —
  não renomear um pensando que é duplicata do outro.
- **Documentação de referência/metodologia** (estudos citados, decisões de
  cálculo) vai em `docs/` — ver `docs/NUTRICAO.md` como exemplo.

## Comandos de verificação

```bash
flutter analyze                                # deve dar "No issues found!"
flutter test                                   # testes de domain/data
cd firestore-tests && npm install && npm test  # testa firestore.rules com o Firebase Emulator Suite
```

## Ambiente Windows + OneDrive (gotcha recorrente)

Se este repo estiver clonado dentro de uma pasta sincronizada por
OneDrive/Dropbox/etc no Windows, builds Android podem falhar de duas formas:

1. O serviço de sincronização transforma arquivos recém-gerados em
   placeholders no meio do build, e o Gradle falha ao apagá-los
   ("Unable to delete directory... process has files open") mesmo sem
   nenhum processo travando o arquivo de verdade. Parar daemons do Gradle
   (`cd android && ./gradlew --stop`) e, se persistir, apagar a pasta
   afetada via `Remove-Item -Recurse -Force` no PowerShell.
2. O prefixo do caminho sincronizado somado aos caminhos profundos que o
   Android Gradle Plugin gera pode estourar o limite de 260 caracteres do
   Windows (MAX_PATH). Fix: definir `custom.buildDir=<caminho curto>` em
   `android/local.properties` (gitignored, específico da máquina) —
   `android/build.gradle.kts` já lê essa propriedade e redireciona o
   buildDir do Gradle para fora da pasta sincronizada quando presente.
   **Efeito colateral**: com o buildDir redirecionado, `flutter build
   apk`/`flutter run` sempre reportam "Gradle build failed to produce an
   .apk file" mesmo quando o build deu certo — o APK real fica em
   `<custom.buildDir>/app/outputs/flutter-apk/app-debug.apk`; instalar
   direto de lá com `adb install -r`.

## Credenciais do Firebase

`android/app/google-services.json` e `lib/firebase_options.dart` **não são
versionados** (saíram do Git em resposta a um alerta do GitGuardian — a
chave não é um segredo real, mas por higiene não fica pública). Existem como
`.example` no repo. Para gerar a versão real localmente: `flutterfire
configure` (ver README.md, seção "Configurar o Firebase", para o passo a
passo completo).

## Testando em dispositivo físico via adb

Ao automatizar toques na UI (`adb shell input tap`), nunca estimar
coordenadas pela posição em pixels de um screenshot — o cálculo de escala
erra fácil e o layout muda entre estados. Usar sempre:
```bash
adb shell uiautomator dump //sdcard/ui.xml   # nota: barra dupla no Git Bash
adb pull //sdcard/ui.xml <caminho-local>
grep -o 'text="ALVO"[^>]*bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' <arquivo>
```
e tocar no centro do `bounds` retornado.

## Onde encontrar mais

- `README.md` — setup completo do Firebase, stack, passo a passo para novo dev.
- `docs/` — documentação de referência (metodologias, estudos citados).
- `handoffrotinagpt.md` (não versionado) — estado da sessão mais recente:
  o que já foi testado manualmente, pendências em aberto, decisões
  recentes. Ler antes de assumir o estado atual do projeto; atualizar ao
  fim de sessões longas.
