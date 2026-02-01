import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'dart:io';
import 'password_screen.dart';
import '../system/index.dart';
import '../utils/auth_error_handler.dart';
import '../widgets/error_widgets.dart';
import '/screen/home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final FocusNode _userFocusNode = FocusNode();
  bool _userLabelUp = false; // Controla si el label está arriba
  bool _isLoading = false; // Para mostrar loading mientras verifica
  bool _showSquare =
      false; // Controla si se muestra el cuadrado después de 1.5s
  final LocalAuthentication _localAuth =
      LocalAuthentication(); // Para biometría

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el focus
    _userFocusNode.addListener(_onUserFocusChange);
    // Escuchar cambios en el texto
    _userController.addListener(_onUserTextChange);

    // Timer para mostrar el cuadrado después de 1.5 segundos
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSquare = true;
        });
      }
    });
  }

  void _onUserFocusChange() {
    setState(() {
      // Si tiene focus o tiene texto, el label sube
      _userLabelUp = _userFocusNode.hasFocus || _userController.text.isNotEmpty;
    });
  }

  void _onUserTextChange() {
    setState(() {
      // Si tiene texto, el label se queda arriba
      _userLabelUp = _userFocusNode.hasFocus || _userController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _userFocusNode.removeListener(_onUserFocusChange);
    _userController.removeListener(_onUserTextChange);
    _userFocusNode.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // Guardar credenciales del usuario para autenticación biométrica
  Future<void> _saveUserCredentials(String username, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_username', username);
    await prefs.setString('saved_password', password);
    await prefs.setBool('biometric_enabled', true);
    debugPrint('✅ Credenciales guardadas para autenticación biométrica');
  }

  // Cargar credenciales guardadas
  Future<Map<String, String?>> _loadUserCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('saved_username'),
      'password': prefs.getString('saved_password'),
    };
  }

  // Método de diagnóstico para biometría
  Future<void> _diagnoseBiometrics() async {
    debugPrint('🔍 === DIAGNÓSTICO DE BIOMETRÍA ===');

    try {
      // 1. Verificar credenciales guardadas
      bool hasCredentials = await _hasStoredCredentials();
      Map<String, String?> credentials = await _loadUserCredentials();
      debugPrint('📱 Credenciales guardadas: $hasCredentials');
      debugPrint('📱 Username guardado: ${credentials['username']}');
      debugPrint(
        '📱 Password guardado: ${credentials['password'] != null ? '[EXISTE]' : '[NO EXISTE]'}',
      );

      // 2. Verificar soporte del dispositivo
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      debugPrint('📱 canCheckBiometrics: $isAvailable');
      debugPrint('📱 isDeviceSupported: $isDeviceSupported');

      // 3. Verificar tipos disponibles
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();
      debugPrint('📱 Tipos disponibles: $availableBiometrics');

      // 4. Mostrar resultado en diálogo
      String diagnosticMessage =
          '''
Credenciales guardadas: $hasCredentials
Username: ${credentials['username'] ?? 'No guardado'}
Password: ${credentials['password'] != null ? 'Guardada' : 'No guardada'}

Soporte biométrico:
- canCheckBiometrics: $isAvailable
- isDeviceSupported: $isDeviceSupported
- Tipos disponibles: $availableBiometrics

Estado: ${hasCredentials && isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty ? 'LISTO PARA USAR' : 'NO DISPONIBLE'}
      ''';

      _showBiometricErrorDialog('Diagnóstico Biométrico', diagnosticMessage);
    } catch (e) {
      debugPrint('❌ Error en diagnóstico: $e');
      _showBiometricErrorDialog('Error de Diagnóstico', 'Error: $e');
    }
  }

  // Verificar si la autenticación biométrica está habilitada
  Future<bool> _isBiometricEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  // Verificar si hay credenciales guardadas
  Future<bool> _hasStoredCredentials() async {
    Map<String, String?> credentials = await _loadUserCredentials();
    return credentials['username'] != null && credentials['password'] != null;
  }

  // Autenticación biométrica
  Future<void> _authenticateWithBiometrics() async {
    try {
      debugPrint('🔐 Iniciando autenticación biométrica...');

      // Verificar si hay credenciales guardadas
      bool hasCredentials = await _hasStoredCredentials();
      debugPrint('📱 Credenciales guardadas: $hasCredentials');

      if (!hasCredentials) {
        debugPrint('❌ No hay credenciales guardadas');
        _showBiometricErrorDialog(
          'Pon el user primero',
          'Debes ingresar tu usuario y contraseña al menos una vez antes de usar la huella.',
        );
        return;
      }

      // Verificar disponibilidad de biometría
      debugPrint('🔍 Verificando disponibilidad de biometría...');
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      debugPrint('📱 Biometría disponible: $isAvailable');
      debugPrint('📱 Dispositivo soportado: $isDeviceSupported');

      if (!isAvailable || !isDeviceSupported) {
        debugPrint('❌ Biometría no disponible o dispositivo no soportado');
        _showBiometricErrorDialog(
          'Biometría no disponible',
          'Tu dispositivo no soporta autenticación biométrica.',
        );
        return;
      }

      // Obtener tipos de biometría disponibles
      debugPrint('🔍 Obteniendo tipos de biometría disponibles...');
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      debugPrint('📱 Tipos disponibles: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        debugPrint('❌ No hay tipos de biometría configurados');
        _showBiometricErrorDialog(
          'Sin biometría configurada',
          'No tienes ningún método biométrico configurado en tu dispositivo.',
        );
        return;
      }

      setState(() => _isLoading = true);
      debugPrint('🔐 Iniciando proceso de autenticación...');

      // Realizar autenticación biométrica
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella para ingresar a la aplicación',
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Autenticación biométrica',
            cancelButton: 'Cancelar',
          ),
        ],
        biometricOnly: false,
      );

      debugPrint('🔐 Resultado de autenticación: $didAuthenticate');

      if (didAuthenticate) {
        // Autenticación exitosa, cargar credenciales y hacer login automático
        debugPrint(
          '✅ Autenticación biométrica exitosa, cargando credenciales...',
        );
        Map<String, String?> credentials = await _loadUserCredentials();
        String? username = credentials['username'];
        String? password = credentials['password'];

        if (username != null && password != null) {
          debugPrint(
            '✅ Autenticación biométrica exitosa para usuario: $username',
          );

          // Navegar directamente a PasswordScreen con las credenciales guardadas
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeScreen(fromPasswordScreen: true),
              ),
            );
          }
        } else {
          debugPrint(
            '❌ Error: credenciales nulas después de autenticación exitosa',
          );
          setState(() => _isLoading = false);
          _showBiometricErrorDialog(
            'Error de credenciales',
            'No se pudieron cargar las credenciales guardadas.',
          );
        }
      } else {
        setState(() => _isLoading = false);
        debugPrint('❌ Autenticación biométrica cancelada o falló');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error en autenticación biométrica: $e');
      debugPrint('❌ Tipo de error: ${e.runtimeType}');

      // Si el usuario canceló, no mostrar ningún error
      if (e.toString().contains('UserCancel') ||
          e.toString().contains('userCanceled') ||
          e.toString().contains('User canceled')) {
        debugPrint(
          '👤 Usuario canceló la autenticación biométrica - No mostrar error',
        );
        return; // Salir sin mostrar diálogo
      }

      String errorMessage = 'Error en la autenticación biométrica';
      String errorTitle = 'Error';

      if (e.toString().contains('NotAvailable')) {
        errorMessage = 'Biometría no disponible en este momento';
        errorTitle = 'No disponible';
      } else if (e.toString().contains('NotEnrolled')) {
        errorMessage = 'No tienes biometría configurada en tu dispositivo';
        errorTitle = 'Sin configurar';
      } else if (e.toString().contains('PermanentlyLockedOut')) {
        errorMessage =
            'Biometría bloqueada. Usa tu PIN o contraseña del dispositivo';
        errorTitle = 'Bloqueado';
      } else if (e.toString().contains('LockedOut')) {
        errorMessage = 'Demasiados intentos fallidos. Espera un momento';
        errorTitle = 'Bloqueado temporalmente';
      } else {
        // Para otros errores técnicos, mostrar mensaje genérico
        errorMessage = 'No se pudo completar la autenticación biométrica';
        errorTitle = 'Error de autenticación';
      }

      _showBiometricErrorDialog(errorTitle, errorMessage);
    }
  }

  // Mostrar diálogo de error biométrico
  void _showBiometricErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
          title: Text(
            title,
            style: TextStyle(color: Colors.orange, fontFamily: 'OpenSansBold'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fingerprint, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontFamily: 'OpenSansRegular',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'OpenSansSemibold',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Clase para verificación robusta de dispositivo
  Future<Map<String, dynamic>> _performSecurityChecks() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> result = {
      'isValid': false,
      'deviceId': '',
      'reason': '',
      'deviceFingerprint': '',
    };

    try {
      // ✅ PERMITIR FLUTTER WEB (Chrome, Edge, etc.)
      if (kIsWeb) {
        debugPrint('🌐 Ejecutándose en Flutter Web - Permitiendo acceso');
        result['deviceId'] =
            'web_browser_${DateTime.now().millisecondsSinceEpoch}';
        result['deviceFingerprint'] =
            'web_${Uri.base.host}_${DateTime.now().day}';
        result['isValid'] = true;
        return result;
      }

      if (!kIsWeb && Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        // Verificaciones anti-emulador para Android
        bool isEmulator = _isAndroidEmulator(androidInfo);
        if (isEmulator) {
          result['reason'] = 'Dispositivo no autorizado: Emulador detectado';
          return result;
        }

        // Crear fingerprint único del dispositivo
        String deviceFingerprint = _createAndroidFingerprint(androidInfo);
        result['deviceId'] = androidInfo.id;
        result['deviceFingerprint'] = deviceFingerprint;
        result['isValid'] = true;
      } else if (!kIsWeb && Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

        // Verificaciones anti-emulador para iOS
        bool isSimulator = _isIOSSimulator(iosInfo);
        if (isSimulator) {
          result['reason'] = 'Dispositivo no autorizado: Simulador detectado';
          return result;
        }

        // Crear fingerprint único del dispositivo
        String deviceFingerprint = _createIOSFingerprint(iosInfo);
        result['deviceId'] = iosInfo.identifierForVendor ?? 'unknown';
        result['deviceFingerprint'] = deviceFingerprint;
        result['isValid'] = true;
      }

      // Verificar si el dispositivo ya está registrado
      bool isDeviceRegistered = await _checkDeviceRegistration(
        result['deviceFingerprint'],
      );
      if (!isDeviceRegistered) {
        await _registerDevice(result['deviceFingerprint']);
      }
    } catch (e) {
      debugPrint('Error en verificaciones de seguridad: $e');
      result['reason'] = 'Error de verificación de dispositivo';
    }

    return result;
  }

  // Detectar emuladores Android
  bool _isAndroidEmulator(AndroidDeviceInfo androidInfo) {
    // Lista de indicadores de emulador
    List<String> emulatorIndicators = [
      'google_sdk',
      'Emulator',
      'Android SDK built for x86',
      'sdk_gphone',
      'generic',
      'goldfish',
      'vbox86p',
      'genymotion',
    ];

    String brand = androidInfo.brand.toLowerCase();
    String device = androidInfo.device.toLowerCase();
    String model = androidInfo.model.toLowerCase();
    String product = androidInfo.product.toLowerCase();
    String hardware = androidInfo.hardware.toLowerCase();

    // Verificar indicadores comunes de emulador
    for (String indicator in emulatorIndicators) {
      if (brand.contains(indicator.toLowerCase()) ||
          device.contains(indicator.toLowerCase()) ||
          model.contains(indicator.toLowerCase()) ||
          product.contains(indicator.toLowerCase()) ||
          hardware.contains(indicator.toLowerCase())) {
        return true;
      }
    }

    // Verificaciones adicionales
    if (androidInfo.isPhysicalDevice == false) return true;
    if (brand == 'generic' && device == 'generic') return true;
    if (model.contains('sdk') || model.contains('emulator')) return true;

    return false;
  }

  // Detectar simuladores iOS
  bool _isIOSSimulator(IosDeviceInfo iosInfo) {
    // En iOS, isPhysicalDevice es la verificación principal
    if (iosInfo.isPhysicalDevice == false) return true;

    // Verificaciones adicionales
    if (iosInfo.model.toLowerCase().contains('simulator')) return true;
    if (iosInfo.name.toLowerCase().contains('simulator')) return true;

    return false;
  }

  // Crear fingerprint único para Android (PERMANENTE)
  String _createAndroidFingerprint(AndroidDeviceInfo info) {
    // Usar identificadores que NO cambian con reinstalación
    List<String> hardwareIdentifiers = [
      info.brand, // Marca del dispositivo (Samsung, Google, etc.)
      info.device, // Nombre del dispositivo
      info.model, // Modelo específico
      info.product, // Producto
      info.board, // Placa base
      info.hardware, // Hardware específico
      info.manufacturer, // Fabricante
      info.id, // Android ID (más estable)
    ];

    // Filtrar valores nulos y crear fingerprint
    String fingerprint = hardwareIdentifiers
        .where((id) => id.isNotEmpty)
        .join('_');

    debugPrint('🔧 Android Fingerprint components: $hardwareIdentifiers');
    return fingerprint.hashCode.toString();
  }

  // Crear fingerprint único para iOS (PERMANENTE)
  String _createIOSFingerprint(IosDeviceInfo info) {
    // Usar identificadores que NO cambian con reinstalación
    List<String> hardwareIdentifiers = [
      info.model, // Modelo del dispositivo
      info.systemName, // iOS
      info.systemVersion, // Versión del sistema
      info.utsname.machine, // Arquitectura del hardware
      info.utsname.nodename, // Nombre del nodo
      info.identifierForVendor ??
          '', // ID del vendor (puede cambiar pero es útil)
    ];

    // Filtrar valores nulos y crear fingerprint
    String fingerprint = hardwareIdentifiers
        .where((id) => id.isNotEmpty)
        .join('_');

    debugPrint('🔧 iOS Fingerprint components: $hardwareIdentifiers');
    return fingerprint.hashCode.toString();
  }

  // Verificar si el dispositivo ya está registrado
  Future<bool> _checkDeviceRegistration(String fingerprint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? registeredFingerprint = prefs.getString('device_fingerprint');

    if (registeredFingerprint == null) {
      return false; // Primera vez
    }

    return registeredFingerprint == fingerprint;
  }

  // Registrar dispositivo
  Future<void> _registerDevice(String fingerprint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('device_fingerprint', fingerprint);
    await prefs.setString(
      'registration_date',
      DateTime.now().toIso8601String(),
    );

    // Generar UUID único para este dispositivo
    String deviceUuid = const Uuid().v4();
    await prefs.setString('device_uuid', deviceUuid);
  }

  void _login() async {
    final username = _userController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔍 Iniciando login para usuario: $username');

      // Realizar verificaciones de seguridad del dispositivo
      debugPrint('🔒 Realizando verificaciones de seguridad...');
      Map<String, dynamic> securityCheck = await _performSecurityChecks();

      if (!securityCheck['isValid']) {
        // Dispositivo no válido (emulador/simulador)
        debugPrint('❌ Dispositivo no válido: ${securityCheck['reason']}');
        if (mounted) {
          setState(() => _isLoading = false);
          _showSecurityErrorDialog(securityCheck['reason']);
        }
        return;
      }

      debugPrint('✅ Dispositivo válido, verificando usuario en Firebase...');

      // Verificar si el usuario existe en la colección 'users'
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .get();

      debugPrint('Documento obtenido. Existe: ${doc.exists}');

      if (doc.exists) {
        // Usuario existe, verificar dispositivo en base de datos
        debugPrint('✅ Usuario encontrado, verificando dispositivo...');
        await _handleUserFound(username, doc.data(), securityCheck);
      } else {
        // Usuario no existe, mostrar error
        debugPrint('❌ Usuario no encontrado en Firestore');
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog();
        }
      }
    } catch (e, stackTrace) {
      // Error de conexión - agregar más detalles de logging
      debugPrint('💥 Error en _login: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage;

        // Verificar tipos específicos de error
        if (e.toString().contains('network') ||
            e.toString().contains('connection') ||
            e.toString().contains('timeout')) {
          errorMessage =
              'Error de conexión. Verifica tu internet y vuelve a intentar';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Error de permisos. Contacta a soporte técnico';
        } else if (e.toString().contains('unavailable')) {
          errorMessage =
              'Servicio temporalmente no disponible. Intenta más tarde';
        } else {
          // Usar el handler original pero con más contexto
          errorMessage = AuthErrorHandler.getFriendlyMessage(e);
          debugPrint('Error procesado por AuthErrorHandler: $errorMessage');
        }

        ErrorSnackBar.show(context, message: errorMessage, isError: true);
      }
    }
  }

  // Manejar cuando el usuario es encontrado
  Future<void> _handleUserFound(
    String username,
    Map<String, dynamic>? userData,
    Map<String, dynamic> securityCheck,
  ) async {
    try {
      // Obtener los valores actuales del dispositivo
      String currentDeviceId = securityCheck['deviceId'];
      String currentDeviceFingerprint = securityCheck['deviceFingerprint'];

      // Obtener los valores guardados en la base de datos
      String? savedDeviceId = userData?['device_id'];
      String? savedDeviceFingerprint = userData?['device_fingerprint'];

      debugPrint('🔍 Verificando dispositivo en base de datos...');
      debugPrint('📱 Device ID actual: $currentDeviceId');
      debugPrint('📱 Device ID guardado: $savedDeviceId');
      debugPrint('🔐 Fingerprint actual: $currentDeviceFingerprint');
      debugPrint('🔐 Fingerprint guardado: $savedDeviceFingerprint');

      // CASO 1: Los campos están vacíos - Primera vez, guardar dispositivo
      if ((savedDeviceId == null || savedDeviceId.isEmpty) &&
          (savedDeviceFingerprint == null || savedDeviceFingerprint.isEmpty)) {
        debugPrint(
          '📝 Primera vez - Registrando dispositivo en base de datos...',
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(username)
            .update({
              'device_id': currentDeviceId,
              'device_fingerprint': currentDeviceFingerprint,
              'last_login': DateTime.now().toIso8601String(),
              'device_registered_at': DateTime.now().toIso8601String(),
            });

        debugPrint('✅ Dispositivo registrado exitosamente');
        _navigateToPassword(username);
        return;
      }

      // CASO 2: Los campos tienen valores - Comparar con dispositivo actual
      if (savedDeviceId != null && savedDeviceFingerprint != null) {
        debugPrint('🔍 Comparando dispositivos...');

        // Verificar si ambos coinciden
        bool deviceIdMatches = savedDeviceId == currentDeviceId;
        bool fingerprintMatches =
            savedDeviceFingerprint == currentDeviceFingerprint;

        debugPrint('📱 Device ID coincide: $deviceIdMatches');
        debugPrint('🔐 Fingerprint coincide: $fingerprintMatches');

        // NUEVA LÓGICA: Permitir acceso si AL MENOS el fingerprint coincide
        if (fingerprintMatches) {
          // ✅ ACCESO PERMITIDO - Hardware coincide
          debugPrint('✅ Dispositivo autorizado - Hardware verificado');

          // Si el Device ID cambió, actualizarlo en la base de datos
          if (!deviceIdMatches) {
            debugPrint('🔄 Actualizando Device ID en base de datos...');
            await FirebaseFirestore.instance
                .collection('users')
                .doc(username)
                .update({
                  'device_id': currentDeviceId,
                  'device_id_updated_at': DateTime.now().toIso8601String(),
                });
          }

          // Actualizar último login
          await FirebaseFirestore.instance
              .collection('users')
              .doc(username)
              .update({'last_login': DateTime.now().toIso8601String()});

          _navigateToPassword(username);
          return;
        } else {
          // ❌ ACCESO DENEGADO - Hardware diferente
          debugPrint('❌ Hardware no autorizado - Acceso denegado');
          if (mounted) {
            setState(() => _isLoading = false);
            _showDeviceConflictDialog();
          }
          return;
        }
      }

      // CASO 3: Solo uno de los campos tiene valor (caso raro, pero manejarlo)
      debugPrint('⚠️ Estado inconsistente en base de datos - Actualizando...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .update({
            'device_id': currentDeviceId,
            'device_fingerprint': currentDeviceFingerprint,
            'last_login': DateTime.now().toIso8601String(),
            'device_updated_at': DateTime.now().toIso8601String(),
          });

      _navigateToPassword(username);
    } catch (e) {
      debugPrint('❌ Error al manejar usuario encontrado: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackBar.show(
          context,
          message: 'Error al verificar dispositivo',
          isError: true,
        );
      }
    }
  }

  void _navigateToPassword(String username) async {
    if (!mounted) return;

    setState(() => _isLoading = false);

    // Guardar credenciales para autenticación biométrica futura
    // Solo guardamos el username aquí, la contraseña se guardará en PasswordScreen
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_username', username);
    debugPrint(
      '✅ Usuario guardado para futura autenticación biométrica: $username',
    );

    // Navegar directamente a PasswordScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PasswordScreen(username: username)),
    );
  }

  void _showSecurityErrorDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
          title: Text(
            '🚫 Acceso Denegado',
            style: TextStyle(color: Colors.red, fontFamily: 'OpenSansBold'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                reason,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontFamily: 'OpenSansRegular',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Esta aplicación solo funciona en dispositivos físicos autorizados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'OpenSansRegular',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop(); // Cerrar la aplicación
              },
              child: Text(
                'Salir',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'OpenSansSemibold',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeviceConflictDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
          title: Text(
            '⚠️ Dispositivo No Autorizado',
            style: TextStyle(color: Colors.orange, fontFamily: 'OpenSansBold'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phonelink_off, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text(
                'Esta cuenta ya está asociada a otro dispositivo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontFamily: 'OpenSansRegular',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Por seguridad, cada cuenta solo puede estar activa en un dispositivo a la vez.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'OpenSansRegular',
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Entendido',
                style: TextStyle(
                  color: Colors.orange,
                  fontFamily: 'OpenSansSemibold',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2E)
              : Colors.white,
          title: Text(
            'Usuario no encontrado',
            style: TextStyle(color: Colors.red, fontFamily: 'OpenSansBold'),
          ),
          content: Text(
            'El usuario no está registrado en el sistema.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontFamily: 'OpenSansRegular',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'OpenSansSemibold',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Variables para posicionar el icono X (ajusta estos valores)
    final double xPosX = screenW * 0.05; // Posición horizontal (90% del ancho)
    final double xPosY = screenH * 0.025; // Posición vertical (2% del alto)
    final double xSize = screenW * 0.08; // Tamaño relativo (6% del ancho)
    final double chevronSize =
        screenW * 0.05; // Tamaño del chevron (ajusta este valor)

    // Variables para controlar la animación del label "Ingrese su usuario"
    final double labelStartX =
        screenW * 0.13; // Posición X inicial (al lado del icono)
    final double labelStartY = screenH * 0.12 * 0.32; // Posición Y inicial
    final double labelEndX =
        screenW * 0.04; // Posición X final (arriba del icono)
    final double labelEndY =
        screenH * 0.25 * 0.08; // Posición Y final (ajusta este valor)

    // Variables para controlar la posición del TextField (donde escribes)
    final double textFieldX = screenW * 0.13; // Posición X del TextField
    final double textFieldY = screenH * 0.18 * 0.25; // Posición Y del TextField

    // Variable para el tamaño del círculo (ajusta este valor)
    final double circleSize = screenW * 0.4;
    // Variable para el tamaño de la animación Lottie (ajusta este valor)
    final double lottieSize = screenW * 2.0;
    // Variables para la posición del círculo (ajusta estos valores)
    final double circlePosX = screenW * 0.52; // Centro horizontal
    final double circlePosY = screenH * 0.65; // Posición vertical
    // Variables para la posición de la animación Lottie (ajusta estos valores)
    final double lottiePosX = screenW * 0.5; // Centro horizontal
    final double lottiePosY = screenH * 0.5; // Posición vertical

    // Variables para el icono fingerprint dentro del círculo (ajusta estos valores)
    final double fingerprintSize =
        circleSize * 0.35; // Tamaño del icono (50% del círculo)
    final double fingerprintOffsetX =
        0.0; // Offset X dentro del círculo (0 = centrado)
    final double fingerprintOffsetY =
        0.0; // Offset Y dentro del círculo (0 = centrado)

    return Stack(
      children: [
        SystemAwareScaffold(
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Stack(
                children: [
                  // Contenido principal
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.08),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenH * 0.02),
                        // Icono CIB centrado
                        Center(
                          child: SvgPicture.asset(
                            'assets/icons/CIB.svg',
                            width: screenW * 0.04,
                            height: screenH * 0.04,
                            fit: BoxFit.contain,
                            colorFilter: isDark
                                ? const ColorFilter.mode(
                                    Color(0xFFF2F2F4),
                                    BlendMode.srcIn,
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(height: screenH * 0.02),
                        // Texto ¡Hola!
                        Text(
                          '¡Hola!',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.08,
                            color: isDark
                                ? const Color(0xFFF2F2F4)
                                : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenH * 0.05),
                        // Cuadrado debajo del Hola (como los de preview)
                        Container(
                          width: screenW * 0.95,
                          height: screenH * 0.12,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Stack(
                            children: [
                              // Icono pic-user arriba de la línea
                              Positioned(
                                left: screenW * 0.04,
                                top:
                                    screenH * 0.12 * 0.35, // Arriba de la línea
                                child: SvgPicture.asset(
                                  'assets/icons/pic-user.svg',
                                  width: screenW * 0.06,
                                  height: screenW * 0.06,
                                  colorFilter: ColorFilter.mode(
                                    isDark
                                        ? const Color(0xFFF2F2F4)
                                        : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              // Texto "Ingrese su usuario" con animación
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                left: _userLabelUp ? labelEndX : labelStartX,
                                top: _userLabelUp ? labelEndY : labelStartY,
                                child: GestureDetector(
                                  onTap: () {
                                    _userFocusNode.requestFocus();
                                  },
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: _userLabelUp
                                          ? screenW * 0.03
                                          : screenW * 0.04,
                                      color: isDark
                                          ? const Color(0xFFF2F2F4)
                                          : Colors.grey,
                                    ),
                                    child: const Text('Ingrese su usuario'),
                                  ),
                                ),
                              ),
                              // TextField para capturar el texto
                              Positioned(
                                left: textFieldX,
                                top: textFieldY,
                                right: screenW * 0.05,
                                child: TextField(
                                  controller: _userController,
                                  focusNode: _userFocusNode,
                                  style: TextStyle(
                                    fontFamily: 'OpenSansRegular',
                                    fontSize: screenW * 0.04,
                                    color: isDark
                                        ? const Color(0xFFF2F2F4)
                                        : Colors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              // Línea horizontal un poco más abajo de la mitad (con márgenes)
                              Positioned(
                                left: screenW * 0.05,
                                right: screenW * 0.05,
                                top: screenH * 0.12 * 0.6, // 60% desde arriba
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 2,
                                  color: _userController.text.isNotEmpty
                                      ? const Color(
                                          0xFFFFD700,
                                        ) // Amarillo cuando hay texto
                                      : (isDark
                                            ? const Color(0xFF5A5A5C)
                                            : const Color(0xFFE0E0E0)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.03),
                        // Botón Continuar
                        SizedBox(
                          width: screenW * 0.95,
                          height: screenH * 0.05,
                          child: ElevatedButton(
                            onPressed:
                                (_userController.text.isNotEmpty && !_isLoading)
                                ? _login
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _userController.text.isNotEmpty
                                  ? const Color(0xFFFFD700)
                                  : const Color(
                                      0xFF9E9E9E,
                                    ).withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                              disabledBackgroundColor: const Color(
                                0xFF9E9E9E,
                              ).withValues(alpha: 0.5),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: screenW * 0.05,
                                    height: screenW * 0.05,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _userController.text.isNotEmpty
                                            ? Colors.black
                                            : Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Continuar',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansSemibold',
                                      fontSize: screenW * 0.045,
                                      color: _userController.text.isNotEmpty
                                          ? Colors.black
                                          : Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: screenH * 0.04),
                        // Texto subrayado "¿Olvidaste tu usuario o clave?"
                        GestureDetector(
                          onTap: () {
                            // Acción al tocar
                          },
                          child: Text(
                            '¿Olvidaste tu usuario o clave?',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.035,
                              color: isDark
                                  ? const Color(0xFFF2F2F4)
                                  : Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(height: screenH * 0.35),
                        // Texto subrayado "¿Aún no tienes usuario o cuenta?"
                        GestureDetector(
                          onTap: () {
                            // Acción al tocar
                          },
                          child: Text(
                            '¿Aún no tienes usuario o cuenta?',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.035,
                              color: isDark
                                  ? const Color(0xFFF2F2F4)
                                  : Colors.black,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(height: screenH * 0.02),
                      ],
                    ),
                  ),
                  // Animación Lottie posicionada (debajo del círculo)
                  Positioned(
                    left: lottiePosX - lottieSize / 2,
                    top: lottiePosY - lottieSize / 2,
                    child: IgnorePointer(
                      child: Lottie.asset(
                        'assets/trazos/06_animate.json',
                        width: lottieSize,
                        height: lottieSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Círculo posicionado (encima del Lottie) con icono fingerprint
                  Positioned(
                    left: circlePosX - circleSize / 2,
                    top: circlePosY - circleSize / 2,
                    child: GestureDetector(
                      onTap:
                          _authenticateWithBiometrics, // Funcionalidad normal de huella
                      onLongPress:
                          _diagnoseBiometrics, // Diagnóstico con presión larga
                      child: Container(
                        width: circleSize,
                        height: circleSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF353537)
                              : Colors.white,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Transform.translate(
                                offset: Offset(
                                  fingerprintOffsetX,
                                  fingerprintOffsetY,
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/pic-id-fingerprint.svg',
                                  width: fingerprintSize,
                                  height: fingerprintSize,
                                  colorFilter: ColorFilter.mode(
                                    isDark
                                        ? const Color(0xFFF2F2F4)
                                        : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenH * 0.01),
                              Text(
                                'Ingresa con\nhuella',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.03,
                                  color: isDark
                                      ? const Color(0xFFF2F2F4)
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Icono X posicionable con texto "Cerrar"
                  Positioned(
                    left: xPosX,
                    top: xPosY,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: xSize,
                            color: isDark
                                ? const Color(0xFFF2F2F4)
                                : Colors.black,
                          ),
                          Text(
                            'Cerrar',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.05,
                              color: isDark
                                  ? const Color(0xFFF2F2F4)
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Texto "Continuar>" en el lado derecho
                  Positioned(
                    right: xPosX,
                    top: xPosY,
                    child: GestureDetector(
                      onTap: () {
                        // Acción de continuar
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Continuar',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.05,
                              color: isDark
                                  ? const Color(0xFFF2F2F4)
                                  : Colors.black,
                            ),
                          ),

                          SizedBox(width: screenW * 0.02),
                          ColorFiltered(
                            colorFilter: isDark
                                ? const ColorFilter.mode(
                                    Color(0xFFF2F2F4),
                                    BlendMode.srcIn,
                                  )
                                : const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.dst,
                                  ),
                            child: Image.asset(
                              'assets/icons/pic-chevron-right.png',
                              width: chevronSize,
                              height: chevronSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Cuadrado centrado en Stack separado
        
      ],
    );
  }
}
