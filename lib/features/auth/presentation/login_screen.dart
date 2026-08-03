import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      context.go('/');
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Une erreur est survenue. Réessaie.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenue sur TCHAKA',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connecte-toi pour continuer.',
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Adresse e-mail',
                      hintText: 'exemple@email.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Se connecter'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Créer un compte',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
