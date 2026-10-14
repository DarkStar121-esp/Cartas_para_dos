import 'package:flutter/material.dart';
import '../core/game_module.dart';
import '../core/game_registry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final classics = GameRegistry.byCategory(GameCategory.classic);
    final couples = GameRegistry.byCategory(GameCategory.couples);

    return Scaffold(
      appBar: AppBar(title: const Text('Cartas para dos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('Para dos'),
          ...couples.map((g) => _GameTile(module: g)),
          const SizedBox(height: 24),
          _SectionTitle('Clásicos'),
          ...classics.map((g) => _GameTile(module: g)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      );
}

class _GameTile extends StatelessWidget {
  final GameModule module;
  const _GameTile({required this.module});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Row(
          children: [
            Text(module.name),
            if (module.isAdultContent) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('+18',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ],
        ),
        subtitle: Text(module.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: module.buildScreen),
        ),
      ),
    );
  }
}
