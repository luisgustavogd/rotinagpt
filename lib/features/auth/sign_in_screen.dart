import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';

/// Tela de login — Sign in with Apple (iOS) e Google (iOS/Android). Sem
/// e-mail/senha próprio: a conta serve só para sincronizar os dados da mesma
/// pessoa entre o iPhone e o Android dela.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(
        () => _error =
            'Não foi possível entrar. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authGateway = ref.read(authGatewayProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.favorite_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'Minha Rotina de Saúde',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'É necessário estar online na primeira vez que você entra. '
                'Depois disso, o app funciona normalmente offline.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (Platform.isIOS)
                FilledButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _signIn(authGateway.signInWithApple),
                  icon: const Icon(Icons.apple),
                  label: const Text('Entrar com Apple'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loading
                    ? null
                    : () => _signIn(authGateway.signInWithGoogle),
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Entrar com Google'),
              ),
              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Este app não é um dispositivo médico e não substitui '
                'orientação profissional.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
