import 'package:flutter/material.dart';
import '../../models/user_account.dart';

class EnterPartnerCodeScreen extends StatefulWidget {
  final UserAccount me;
  final Future<void> Function(String code) onSendRequest;

  const EnterPartnerCodeScreen({
    super.key,
    required this.me,
    required this.onSendRequest,
  });

  @override
  State<EnterPartnerCodeScreen> createState() => _EnterPartnerCodeScreenState();
}

class _EnterPartnerCodeScreenState extends State<EnterPartnerCodeScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length < 4) return;
    setState(() => _sending = true);
    try {
      await widget.onSendRequest(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada. Esperando que tu pareja confirme…')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Código de tu pareja')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 4),
              decoration: const InputDecoration(
                labelText: 'Código',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _sending ? null : _send,
              child: _sending
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Enviar solicitud'),
            ),
          ],
        ),
      ),
    );
  }
}
