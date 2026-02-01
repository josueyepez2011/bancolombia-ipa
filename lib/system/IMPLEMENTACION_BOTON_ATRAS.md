# Implementación del Sistema de Botón Atrás

## ✅ Lo que ya está listo

He agregado al archivo `lib/system/system.dart` las siguientes funcionalidades:

1. **`BackButtonNavigationHandler`**: Clase que maneja la lógica del botón atrás
2. **`SystemAwareScaffold` mejorado**: Ahora incluye manejo automático del botón atrás

## 🔧 Pasos para implementar

### 1. Modificar el HomeScreen

En `lib/screen/home.dart`, busca la línea aproximada 293 donde dice:

```dart
return ErrorHandlerScreen(
  child: Scaffold(
    backgroundColor: restColor,
    // ...
  ),
);
```

Y reemplázala con:

```dart
return ErrorHandlerScreen(
  child: SystemAwareScaffold(
    homeRouteName: '/home',
    backgroundColor: restColor,
    body: Material(
      // ... resto del contenido sin cambios
    ),
  ),
);
```

### 2. Configurar las rutas en main.dart

En `lib/main.dart`, en el `MaterialApp`, agrega o modifica las rutas:

```dart
MaterialApp(
  routes: {
    '/home': (context) => const HomeScreen(),
    // ... otras rutas que tengas
  },
  // ... resto de la configuración
)
```

### 3. Modificar otras pantallas (opcional pero recomendado)

Para cualquier otra pantalla de la app (como `transferir_plata_screen.dart`, `bre-b_screen.dart`, etc.), reemplaza `Scaffold` con `SystemAwareScaffold`:

```dart
// ANTES:
return Scaffold(
  appBar: AppBar(...),
  body: YourContent(),
);

// DESPUÉS:
return SystemAwareScaffold(
  homeRouteName: '/home',
  appBar: AppBar(...),
  body: YourContent(),
);
```

## 🎯 Comportamiento resultante

- **Desde cualquier pantalla**: Al presionar el botón atrás del dispositivo → va al Home
- **Desde el Home**: Al presionar el botón atrás del dispositivo → sale de la aplicación

## 📝 Notas importantes

1. **Solo necesitas cambiar el HomeScreen** para que funcione básicamente
2. **Las otras pantallas son opcionales** - si no las cambias, seguirán funcionando como antes
3. **El sistema es automático** - no necesitas escribir lógica adicional
4. **Es compatible** con el sistema existente de tu app

## 🧪 Para probar

1. Implementa los cambios en HomeScreen y main.dart
2. Ejecuta la app
3. Navega a cualquier pantalla
4. Presiona el botón atrás del dispositivo
5. Deberías ir al Home
6. Desde el Home, presiona atrás nuevamente
7. Deberías salir de la app

## ❓ Si tienes problemas

- Verifica que la ruta '/home' esté configurada en MaterialApp
- Asegúrate de que HomeScreen use `homeRouteName: '/home'`
- Revisa que no haya otros `PopScope` o `WillPopScope` que interfieran