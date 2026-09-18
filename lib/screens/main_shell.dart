import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Solo dejamos que el botón atrás cierre la app de verdad si ya
      // estamos en la primera pestaña (Juegos). Si no, lo interceptamos
      // y volvemos ahí primero — sin esto, el botón atrás salía
      // directamente de la app desde "Perfil" porque el IndexedStack no
      // deja ningún registro de navegación por sí solo.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [HomeScreen(), ProfileScreen()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.style_outlined), selectedIcon: Icon(Icons.style), label: 'Juegos'),
            NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
