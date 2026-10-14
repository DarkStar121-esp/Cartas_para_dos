import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_session.dart';
import '../core/dev/dev_account_switcher.dart';
import 'auth/sign_in_screen.dart';
import 'main_shell.dart';
import 'onboarding/create_account_screen.dart';
import 'pairing/pairing_flow_screen.dart';

/// Decide qué pantalla mostrar según el estado de [AppSession]:
/// sin sesión → login; logueado sin cuenta → alta de cuenta; con cuenta
/// pero sin pareja → pairing; emparejado → la app (juegos + perfil).
///
/// El FAB de desarrollo (DevAccountSwitcherFab) se muestra encima de
/// cualquiera de estas pantallas — es útil en las cuatro, no solo en la
/// principal (por ejemplo, para revisar el pairing con dos cuentas antes
/// de llegar a MainShell).
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();

    late final Widget screen;
    if (!session.isSignedIn) {
      screen = SignInScreen(onSignIn: session.signIn);
    } else if (!session.hasAccount) {
      screen = CreateAccountScreen(
        firstNameFromGoogle: '',
        onSubmit: ({required firstName, required lastName, required age, required gender}) {
          session.completeAccountCreation(
            firstName: firstName,
            lastName: lastName,
            age: age,
            gender: gender,
          );
        },
      );
    } else if (!session.isPaired) {
      screen = const PairingFlowScreen();
    } else {
      screen = const MainShell();
    }

    return Stack(
      children: [
        screen,
        const DevAccountSwitcherFab(),
      ],
    );
  }
}
