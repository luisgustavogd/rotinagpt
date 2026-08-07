# Minha Rotina de Saúde

App pessoal para organizar alimentação, proteína, peso, medidas, medicação
informativa (ex.: tirzepatida/Mounjaro), exames laboratoriais e atividade
física — com foco em reduzir a fricção de registrar, visualizar e cumprir uma
rotina diária.

**Este app é uma ferramenta de organização e acompanhamento pessoal. Ele não é
um dispositivo médico, não diagnostica, não prescreve e nunca sugere alterar
dose de medicação. Consulte sempre um profissional de saúde.**

## Stack

- **Flutter** (Dart) — um único codebase compilando nativamente para iOS e
  Android.
- **Firebase** — Firestore (persistência com cache/sincronização offline
  nativa) + Firebase Auth. Sem servidor próprio.
- **Autenticação**: Sign in with Apple (iOS) + Google Sign-In — sem
  e-mail/senha próprio. A conta serve só para sincronizar os dados entre os
  aparelhos da mesma pessoa; não há suporte a múltiplos usuários/contas
  compartilhadas.
- **Riverpod** (DI/estado), **go_router** (navegação com guarda de
  autenticação), **flutter_local_notifications** (lembretes locais),
  **fl_chart** (gráficos), **pdf**/**printing**/**archive**/**crypto**
  (relatórios e backup).

## Arquitetura

```
lib/
├── app/            # app.dart, router.dart (guarda de auth), theme.dart
├── core/           # DI (Riverpod), erro, log, prefs puramente locais
├── domain/         # Dart puro: entidades e regras de negócio (RN-001..010),
│                   # sem nenhuma dependência de Flutter ou Firebase
├── data/           # implementações: Firestore (remote/), auth, notificações,
│                   # backup — cada uma implementando uma interface de domain/
└── features/       # telas por área: auth, onboarding, today, nutrition,
                    # progress, routine, health, settings, shell (nav)
```

## Documentação

Documentação mais longa (referências de estudos usados em cálculos, decisões
de produto, regras de negócio detalhadas) fica em [`docs/`](docs/), fora
deste README. Hoje inclui:

- [`docs/NUTRICAO.md`](docs/NUTRICAO.md) — metodologia e referência do
  estudo usado para sugerir a meta diária de proteína.

`domain` nunca depende de `data` nem de Flutter — só o contrário. Isso permite
testar toda regra de negócio (soma de proteína, médias, checagem de dose,
duplicidade de medicação, adesão semanal, agendamento de lembretes, diff de
backup) sem subir Firebase nem um widget sequer — veja `test/domain/`.

Todos os dados vivem no Firestore sob `/users/{uid}/...`, e o cache offline
nativo do `cloud_firestore` já cumpre o papel de "funciona sem internet,
sincroniza quando a rede voltar" — não há uma segunda base local em paralelo.

## Configurar o Firebase (obrigatório antes de rodar)

Este repositório não inclui credenciais de um projeto Firebase real (elas são
pessoais e não fazem sentido versionadas por terceiros). Para rodar:

1. Instale a [Firebase CLI](https://firebase.google.com/docs/cli) e o
   [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):
   ```
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```
2. Crie um projeto no [Firebase Console](https://console.firebase.google.com/).
3. Na raiz do repositório, rode:
   ```
   flutterfire configure
   ```
   Isso gera `lib/firebase_options.dart`, `android/app/google-services.json`
   e `ios/Runner/GoogleService-Info.plist` com as credenciais do seu projeto
   (modelo em `*.example` ao lado de cada um). Essas credenciais identificam
   o app e não funcionam como segredo por si só — a segurança vem das
   Security Rules, do Firebase Auth e do App Check — mas por padrão de
   higiene (evitar scanners de segredo, scraping automatizado) esses três
   arquivos ficam fora do Git (`.gitignore`); cada pessoa que clonar o repo
   gera a própria versão local rodando `flutterfire configure`.
4. No Firebase Console, habilite:
   - **Firestore Database** (modo produção).
   - **Authentication** → provedores **Apple** e **Google**.
5. Publique as regras de segurança (`firestore.rules` já está pronto neste
   repo):
   ```
   firebase deploy --only firestore:rules
   ```
6. Configuração específica de plataforma:
   - **iOS**: `ios/Runner/Runner.entitlements` (com a entitlement de Sign in
     with Apple) já existe e já está referenciado no projeto Xcode
     (`CODE_SIGN_ENTITLEMENTS`). Abra `ios/Runner.xcworkspace` no Xcode →
     target Runner → Signing & Capabilities e confirme que "Sign in with
     Apple" aparece habilitado; se não aparecer, adicione via "+ Capability"
     (o Xcode reaproveita o arquivo existente).
   - **Android**: registre o SHA-1/SHA-256 de debug e release do seu keystore
     no projeto Firebase, para o Google Sign-In funcionar
     (`./gradlew signingReport` mostra os hashes).
7. (Opcional, recomendado antes de publicar) Configure o **Firebase App
   Check** (DeviceCheck/App Attest no iOS, Play Integrity no Android) — pode
   ser feito em modo "debug provider" durante o desenvolvimento.

## Rodando

```
flutter pub get
flutter run
```

## Testes

```
flutter analyze
flutter test
```

- `test/domain/` — regras de negócio puras (RN-001 a RN-010 e cálculos de
  RF), sem Firebase.
- `test/data/` — repositórios e o fluxo de backup/restauração usando
  `fake_cloud_firestore`.
- `firestore-tests/` — testes das Security Rules (`firestore.rules`) via
  Firebase Local Emulator Suite, confirmando que um `uid` nunca lê nem
  escreve documento de outro e que acesso não autenticado é sempre negado:
  ```
  cd firestore-tests
  npm install
  npm test
  ```
  (a primeira execução baixa o emulador do Firestore; precisa de rede
  liberada para `storage.googleapis.com`/`firebase.google.com`.)

## Privacidade e limites (leia antes de usar)

- Nenhum dado sai do aparelho sem ação e consentimento explícitos.
- Cada documento no Firestore é restrito ao próprio usuário autenticado
  (`firestore.rules`), tanto para leitura quanto escrita.
- O app nunca sugere aumentar, reduzir, atrasar, antecipar ou interromper uma
  dose de medicação (RF-044) — ele apenas registra o que foi informado.
- Sintomas e resultados de exames são sempre autorrelatados/descritivos,
  nunca interpretados como diagnóstico.
- Metas de peso e proteína são definidas manualmente pelo usuário e devem ser
  validadas por um profissional de saúde.

## Escopo desta versão (MVP) vs. próximas fases

Implementado: painel "Hoje", alimentação/proteína, peso/cintura/gráficos,
medicação (plano, aplicação, sintomas), atividade física (plano semanal,
execução, esforço), exames manuais, lembretes locais, exportação
CSV/PDF, backup/restauração/exclusão de dados.

Deixado como ponto de extensão (interfaces prontas em `domain/health` e
`domain/security`, com implementações "no-op" em `data/`, para não exigir
retrabalho depois):

- **Fase 2**: HealthKit (iOS) / Health Connect (Android), bloqueio de app por
  Face ID/biometria (complementar ao login, não substituto), fotos de
  evolução, histórico de edição de metas na UI (o dado já é guardado desde o
  MVP), backup automático via iCloud/Google Drive.
- **Fase 3**: leitura estruturada (OCR) de laudos de exame.
- **Fase 4**: Apple Watch, widgets, atalhos de voz/Siri.
