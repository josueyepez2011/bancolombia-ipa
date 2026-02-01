// EJEMPLO DE CÓMO MODIFICAR EL HomeScreen ACTUAL PARA USAR EL NUEVO SISTEMA

// ANTES (línea aproximada 293 en home.dart):
/*
return ErrorHandlerScreen(
  child: Scaffold(
    backgroundColor: restColor,
    body: Material(
      // ... resto del contenido
    ),
  ),
);
*/

// DESPUÉS - Reemplazar con:
/*
return ErrorHandlerScreen(
  child: SystemAwareScaffold(
    homeRouteName: '/home', // Especifica que esta es la pantalla home
    backgroundColor: restColor,
    handleBackButton: true, // Habilita el manejo del botón atrás
    body: Material(
      // ... resto del contenido (sin cambios)
    ),
  ),
);
*/

// CONFIGURACIÓN ADICIONAL NECESARIA EN main.dart:

// En el MaterialApp, agregar o modificar las rutas:
/*
MaterialApp(
  routes: {
    '/home': (context) => const HomeScreen(),
    // ... otras rutas existentes
  },
  // ... resto de la configuración
)
*/

// PARA OTRAS PANTALLAS DE LA APP:

// Ejemplo para transferir_plata_screen.dart, bre-b_screen.dart, etc.:
/*
// ANTES:
return Scaffold(
  appBar: AppBar(...),
  body: YourContent(),
);

// DESPUÉS:
return SystemAwareScaffold(
  homeRouteName: '/home', // Al presionar atrás, irá al home
  appBar: AppBar(...),
  body: YourContent(),
);
*/

// NOTAS IMPORTANTES:
// 1. El HomeScreen debe tener la ruta '/home' configurada en MaterialApp
// 2. Todas las demás pantallas deben usar homeRouteName: '/home'
// 3. El sistema detecta automáticamente si estás en home o en otra pantalla
// 4. Si estás en home y presionas atrás → sale de la app
// 5. Si estás en cualquier otra pantalla y presionas atrás → va al home
