import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget simple para manejar el botón de atrás
/// Úsalo envolviendo cualquier pantalla
class SimpleBackHandler extends StatelessWidget {
  final Widget child;
  final bool isHomeScreen;
  final VoidCallback? onBackToHome;

  const SimpleBackHandler({
    super.key,
    required this.child,
    this.isHomeScreen = false,
    this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (isHomeScreen) {
            // Si estamos en home, salir de la app
            SystemNavigator.pop();
          } else {
            // Si no estamos en home, ir al home
            if (onBackToHome != null) {
              onBackToHome!();
            } else {
              // Comportamiento por defecto: ir al home usando Navigator
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          }
        }
      },
      child: child,
    );
  }
}

/// Función helper para envolver fácilmente cualquier pantalla
Widget wrapWithBackHandler({
  required Widget child,
  bool isHomeScreen = false,
  VoidCallback? onBackToHome,
}) {
  return SimpleBackHandler(
    isHomeScreen: isHomeScreen,
    onBackToHome: onBackToHome,
    child: child,
  );
}