import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  /// Devuelve true si se inició sesión, false si la persona canceló el
  /// selector de cuenta (no es un error). Puede lanzar una excepción
  /// real (red, configuración de Firebase, etc.) — esta pantalla la
  /// atrapa y la muestra.
  final Future<bool> Function() onSignIn;
  const SignInScreen({super.key, required this.onSignIn});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _loading = false;

  Future<void> _handleSignIn() async {
    setState(() => _loading = true);
    try {
      await widget.onSignIn();
      // false (cancelado) no necesita feedback — la persona ya sabe
      // que cerró el selector de cuenta ella misma.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar sesión: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 64, color: Colors.deepPurple),
              const SizedBox(height: 16),
              Text('Cartas para dos', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Iniciá sesión para crear tu cuenta y conectarte con tu pareja',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _loading ? null : _handleSignIn,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: const Text('Continuar con Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
