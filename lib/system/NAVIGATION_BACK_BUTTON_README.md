# Sistema de Manejo del Botón de Atrás

Este sistema permite manejar automáticamente el botón de atrás del dispositivo Android para que:

1. **Desde cualquier pantalla**: Al presionar atrás, siempre vaya al Home
2. **Desde el Home**: Al presionar atrás, salga de la aplicación

## Cómo Usar

### 1. Configurar la Pantalla Home

En tu pantalla Home (por ejemplo, `HomeScreen`), usa `SystemAwareScaffold` y especifica que es el home:

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SystemAwareScaffold(
      homeRouteName: '/home', // Especifica que esta es la ruta del home
      body: YourHomeContent(),
    );
  }
}
```

### 2. Configurar Pantallas Secundarias

En cualquier otra pantalla, usa `SystemAwareScaffold` con la misma `homeRouteName`:

```dart
class AnyOtherScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SystemAwareScaffold(
      homeRouteName: '/home', // Al presionar atrás, irá a esta ruta
      appBar: AppBar(title: Text('Otra Pantalla')),
      body: YourContent(),
    );
  }
}
```

### 3. Configurar las Rutas en main.dart

Asegúrate de que tu `MaterialApp` tenga las rutas configuradas:

```dart
MaterialApp(
  routes: {
    '/home': (context) => HomeScreen(),
    '/other': (context) => OtherScreen(),
    // ... más rutas
  },
  home: LogoPantalla(), // Tu pantalla de splash
)
```

## Opciones Avanzadas

### Manejo Personalizado del Botón Atrás

Si necesitas un comportamiento específico en alguna pantalla:

```dart
SystemAwareScaffold(
  onBackPressed: () {
    // Tu lógica personalizada aquí
    showDialog(...);
  },
  body: YourContent(),
)
```

### Desactivar el Manejo Automático

Si quieres que una pantalla use el comportamiento por defecto de Flutter:

```dart
SystemAwareScaffold(
  handleBackButton: false, // Desactiva el manejo automático
  body: YourContent(),
)
```

## Implementación Actual

El sistema funciona de la siguiente manera:

1. **Detección de Pantalla**: Verifica si la pantalla actual es el Home usando `ModalRoute.of(context)?.settings.name`
2. **Lógica de Navegación**:
   - Si está en Home → `SystemNavigator.pop()` (sale de la app)
   - Si no está en Home → `Navigator.pushNamedAndRemoveUntil(homeRouteName, (route) => false)` (va al Home)

## Migración de Pantallas Existentes

Para migrar tus pantallas existentes:

1. Reemplaza `Scaffold` con `SystemAwareScaffold`
2. Agrega `homeRouteName: '/home'` (o la ruta que uses para tu home)
3. Si usas `PopScope` o `WillPopScope`, puedes removerlos ya que `SystemAwareScaffold` los maneja automáticamente

## Ejemplo Completo

Ver `lib/system/navigation_example.dart` para ejemplos completos de implementación.