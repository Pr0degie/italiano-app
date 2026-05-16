import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app_shell.dart';
import 'core/database/providers.dart';
import 'core/seeding/seeder.dart';

void main() {
  runApp(const ProviderScope(child: ItalianoApp()));
}

class ItalianoApp extends ConsumerStatefulWidget {
  const ItalianoApp({super.key});

  @override
  ConsumerState<ItalianoApp> createState() => _ItalianoAppState();
}

class _ItalianoAppState extends ConsumerState<ItalianoApp> {
  late final Future<void> _bootstrap = _runBootstrap();

  Future<void> _runBootstrap() async {
    final db = ref.read(appDatabaseProvider);
    await ContentSeeder(db).seedIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Italiano',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: FutureBuilder<void>(
        future: _bootstrap,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(child: Text('Fehler: ${snapshot.error}')),
            );
          }
          return const AppShell();
        },
      ),
    );
  }
}
