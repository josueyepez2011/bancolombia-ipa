import 'dart:math' as math;
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ajuste.dart';
import 'transferir_plata_screen.dart';
import 'transacciones.dart';
import 'select_qr.dart';
import '../login/login_screen.dart';
import '../system/index.dart';
import '../main.dart';
import '../screen/movimiento_screen.dart';
import '../widgets/mas_opciones_container.dart';
import '../widgets/error_widgets.dart';

class PreviewScreen extends StatefulWidget {
  final bool fromPasswordScreen;

  const PreviewScreen({super.key, this.fromPasswordScreen = false});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false; // Estado: expandido o no
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  // Listener para detectar sesión invalidada
  StreamSubscription<DocumentSnapshot>? _sessionListener;

  // Shimmer loading state
  bool _showShimmer = false;

  // Variables para control de versión
  final String _currentVersion = "1.2.6"; // Versión actual de la app
  bool _hasNewVersion = false;
  String _updateLink = "";
  bool _isCheckingVersion = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOut,
    );
    _scrollController.addListener(_onScroll);
    _startSessionListener();

    // Consultar la colección version e imprimir los IDs
    _consultarVersiones();

    // Iniciar shimmer si viene de password_screen
    if (widget.fromPasswordScreen) {
      _showShimmer = true;
      Future.delayed(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _showShimmer = false;
          });
        }
      });
    }
  }

  /// Inicia el listener para detectar si la sesión fue invalidada
  Future<void> _startSessionListener() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedUsername = prefs.getString('logged_username') ?? '';
    final localSessionToken = prefs.getString('session_token') ?? '';

    if (loggedUsername.isEmpty) return;

    // Si es sesión duplicada, mostrar diálogo bloqueante inmediatamente
    if (localSessionToken == 'DUPLICATE_SESSION') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDuplicateSessionDialog();
      });
      return;
    }

    if (localSessionToken.isEmpty) return;

    _sessionListener = FirebaseFirestore.instance
        .collection('users')
        .doc(loggedUsername)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists) return;

          final data = snapshot.data();
          final firebaseSessionToken = data?['session_token']?.toString() ?? '';

          // Si el token de Firebase es diferente al local, la sesión fue invalidada
          if (firebaseSessionToken.isNotEmpty &&
              firebaseSessionToken != localSessionToken) {
            _forceLogout();
          }
        });
  }

  /// Consulta la colección 'version' e imprime solo la versión más alta que supere 1.2.3
  Future<void> _consultarVersiones() async {
    try {
      print('=== Consultando colección "version" ===');

      // Versión de referencia
      const String versionReferencia = "1.2.6";

      // Obtener todos los documentos de la colección 'version'
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('version')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('La colección "version" está vacía o no existe');
        return;
      }

      String? versionMasAlta;
      String? idMasAlto;
      Map<String, dynamic>? datosMasAltos;

      print('Buscando versiones superiores a $versionReferencia...');

      // Revisar cada documento
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        // Buscar el campo version en los datos
        String? versionDoc;
        if (data != null) {
          // Intentar diferentes nombres de campo comunes
          versionDoc =
              data['version']?.toString() ??
              data['numero']?.toString() ??
              data['ver']?.toString() ??
              doc.id; // Si no hay campo version, usar el ID
        } else {
          versionDoc = doc.id; // Usar el ID como versión
        }

        // Verificar si es una versión válida y mayor a la referencia
        if (versionDoc != null && _esVersionValida(versionDoc)) {
          if (_compararVersiones(versionDoc, versionReferencia) > 0) {
            // Esta versión es mayor a la referencia
            if (versionMasAlta == null ||
                _compararVersiones(versionDoc, versionMasAlta) > 0) {
              versionMasAlta = versionDoc;
              idMasAlto = doc.id;
              datosMasAltos = data;
            }
          }
        }
      }

      if (versionMasAlta != null) {
        print('✅ VERSIÓN MÁS ALTA ENCONTRADA:');
        print('   ID del documento: $idMasAlto');
        print('   Versión: $versionMasAlta');

        // Imprimir todos los campos del documento
        if (datosMasAltos != null && datosMasAltos.isNotEmpty) {
          print('   📋 TODOS LOS CAMPOS DEL DOCUMENTO:');
          datosMasAltos.forEach((campo, valor) {
            print('      • $campo: $valor (${valor.runtimeType})');
          });

          // Actualizar variables de estado para mostrar UI de actualización
          final String? linkActualizacion = datosMasAltos['link']?.toString();
          if (linkActualizacion != null && linkActualizacion.isNotEmpty) {
            setState(() {
              _hasNewVersion = true;
              _updateLink = linkActualizacion;
            });
            print(
              '   🔗 Link de actualización configurado: $linkActualizacion',
            );
          } else {
            print(
              '   ⚠️  No se encontró el campo "link" para la actualización',
            );
          }
        } else {
          print('   ⚠️  El documento no tiene campos adicionales o está vacío');
        }
      } else {
        print('❌ No se encontraron versiones superiores a $versionReferencia');
        // Asegurar que no se muestre UI de actualización si no hay versión nueva
        setState(() {
          _hasNewVersion = false;
          _updateLink = "";
        });
      }

      print('=== Fin de consulta colección "version" ===');
    } catch (e) {
      print('Error al consultar la colección "version": $e');
    }
  }

  /// Verifica si una cadena tiene formato de versión válido (x.y.z)
  bool _esVersionValida(String version) {
    final RegExp versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
    return versionRegex.hasMatch(version);
  }

  /// Compara dos versiones semánticas
  /// Retorna: 1 si version1 > version2, -1 si version1 < version2, 0 si son iguales
  int _compararVersiones(String version1, String version2) {
    final List<int> v1Parts = version1.split('.').map(int.parse).toList();
    final List<int> v2Parts = version2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final int v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final int v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part > v2Part) return 1;
      if (v1Part < v2Part) return -1;
    }

    return 0; // Son iguales
  }

  /// Abre la URL de actualización
  Future<void> _abrirLinkActualizacion() async {
    if (_updateLink.isNotEmpty) {
      try {
        final Uri url = Uri.parse(_updateLink);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          print('✅ Abriendo link de actualización: $_updateLink');
        } else {
          print('❌ No se puede abrir el link: $_updateLink');
          if (mounted) {
            context.showError(
              message: 'No se puede abrir el enlace de actualización',
              title: 'Error',
            );
          }
        }
      } catch (e) {
        print('❌ Error al abrir el link: $e');
        if (mounted) {
          context.showError(
            message: 'Error al abrir el enlace: $e',
            title: 'Error',
          );
        }
      }
    }
  }

  /// Muestra diálogo bloqueante cuando hay sesión duplicada
  void _showDuplicateSessionDialog() {
    ErrorDialog.show(
      context,
      title: 'Sesión activa',
      message:
          'Esta sesión ya está iniciada en otro dispositivo.\n\n'
          'Solo puedes tener una sesión activa a la vez.',
      buttonText: 'Cerrar',
      onPressed: _forceLogoutDuplicate,
    );
  }

  /// Cierra sesión para sesiones duplicadas (sin tocar Firebase)
  Future<void> _forceLogoutDuplicate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_username');
    await prefs.remove('session_token');
    await prefs.setDouble('saldo_reserva', 0);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogoPantalla()),
        (route) => false,
      );
    }
  }

  /// Cierra sesión forzadamente cuando se detecta otra sesión activa
  Future<void> _forceLogout() async {
    _sessionListener?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_username');
    await prefs.remove('session_token');
    await prefs.setDouble('saldo_reserva', 0);

    if (mounted) {
      // Mostrar mensaje y redirigir al splash
      context.showError(
        message: 'Sesión cerrada: se inició sesión en otro dispositivo',
        title: 'Sesión cerrada',
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LogoPantalla()),
        (route) => false,
      );
    }
  }

  // Límite máximo del scroll - ahora se calcula de forma relativa
  double _getMaxScrollOffset(double screenHeight) {
    // Pantallas más grandes = menos scroll, más pequeñas = más scroll
    // Base: ~12% de la altura de pantalla
    return screenHeight * 0.3;
  }

  void _onScroll() {
    setState(() {
      // El límite se recalcula en build, aquí solo actualizamos el offset
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _sessionListener?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onQrTap() {
    if (_isExpanded) {
      // Si está expandido, contraer
      _expandController.reverse();
      setState(() {
        _isExpanded = false;
      });
    } else {
      // Si está contraído, expandir
      _expandController.forward();
      setState(() {
        _isExpanded = true;
      });
    }
  }

  // Función para cerrar sesión y sumar el saldo al Firebase
  Future<void> _handleLogout(BuildContext context) async {
    _sessionListener?.cancel(); // Cancelar listener antes de logout

    try {
      final prefs = await SharedPreferences.getInstance();
      final loggedUsername = prefs.getString('logged_username') ?? '';
      final saldoHome = prefs.getDouble('saldo_reserva') ?? 0;

      if (loggedUsername.isNotEmpty) {
        // Obtener el saldo actual de Firebase
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(loggedUsername)
            .get();

        if (doc.exists) {
          final data = doc.data();
          final saldoFirebase = (data?['saldo'] is num)
              ? (data!['saldo'] as num).toDouble()
              : 0.0;

          // Sumar el saldo del home al saldo de Firebase
          final nuevoSaldo = saldoFirebase + saldoHome;

          // Actualizar Firebase: saldo, limpiar device_id, device_fingerprint y session_token
          await FirebaseFirestore.instance
              .collection('users')
              .doc(loggedUsername)
              .update({
                'saldo': nuevoSaldo,
                'device_id': '', // Limpiar el device_id
                'device_fingerprint': '', // Limpiar el device_fingerprint
                'session_token': '', // Limpiar el session_token
                'session_timestamp': 0, // Limpiar el timestamp
              });

          debugPrint(
            'Saldo actualizado: $saldoFirebase + $saldoHome = $nuevoSaldo',
          );
          debugPrint('device_id, device_fingerprint y session_token limpiados');
        }
      }

      // Limpiar el saldo del home
      await prefs.setDouble('saldo_reserva', 0);

      // Limpiar el usuario logueado y session_token
      await prefs.remove('logged_username');
      await prefs.remove('session_token');

      // Navegar al splash (main.dart)
      if (context.mounted) {
        context.showSuccess(
          message: 'Sesión cerrada correctamente',
          title: 'Sesión cerrada',
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LogoPantalla()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      if (context.mounted) {
        context.showError(message: 'Error al cerrar sesión', title: 'Error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    final double screenW = MediaQuery.of(context).size.width;
    final double maxScrollOffset = _getMaxScrollOffset(screenH);
    // Aplicar el clamp aquí con el valor relativo
    final double clampedScrollOffset = _scrollOffset.clamp(
      0.0,
      maxScrollOffset,
    );
    final double quarterHeight = screenH / 4;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color restColor = isDark
        ? const Color(0xFF282827)
        : const Color(0xFFF2F2F4);

    // Tamaños de fuente adaptativos con límites
    final double titleFontSize = (screenH * 0.02).clamp(14.0, 18.0);

    return ErrorHandlerScreen(
      child: Scaffold(
        backgroundColor: restColor,
        body: Material(
          clipBehavior: Clip.none,
          color: Colors.transparent,
          child: FullScreenSystemAware(
            respectStatusBar: false,
            respectNavigationBar: false,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                // Fondo que se mueve con scroll
                Transform.translate(
                  offset: Offset(0, -clampedScrollOffset),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: screenH + maxScrollOffset + 400,
                    child: Column(
                      children: [
                        Container(
                          height: quarterHeight,
                          color: const Color(0xFF333335),
                        ),
                        Expanded(child: Container(color: restColor)),
                      ],
                    ),
                  ),
                ),

                // Área scrolleable (transparente, controla el scroll)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: -300,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: Container(
                      height:
                          screenH +
                          maxScrollOffset +
                          500, // altura aumentada para que no se corte el widget
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // Capa SVG independiente - SE MUEVE CON SCROLL
                Positioned(
                  left: screenW * 0.96 - (screenW * 0.5) / 2,
                  top: screenH * 0.21 - (screenH * 0.3) / 2,
                  width: screenW * 0.3,
                  height: screenH * 0.3,
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/trazos/trazo_preview.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // ========== CONTENIDO SCROLLEABLE (desde "Hola" hacia abajo) ==========
                // Texto interactivo: "hola" + nombre - se mueve con scroll
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: InteractiveTextPair(
                      initialHolaOffsetX: 0.12,
                      initialNameOffsetX: 0.28,
                      offsetY: 0.12,
                      initialScale: 1.2,
                    ),
                  ),
                ),
                // Cuadrado interactivo - se mueve con scroll
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: InteractiveSquare(
                      initialOffsetX: 0.95,
                      initialOffsetY: 0.055,
                      widthFrac: 0.06,
                      heightFrac: 0.06,
                      initialScale: 0.07,
                      initialBorderRadius: 8.0,
                      color: const Color(0xFF454648),
                    ),
                  ),
                ),
                // Cuadrado blanco con control de posición Y - ocupa todo el ancho con bordes - SE MUEVE CON SCROLL
                Positioned(
                  left: 16,
                  right: 16,
                  top: screenH * 0.32 - clampedScrollOffset,
                  child: Container(
                    height: screenH * 0.2,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        // Parte izquierda - 1/6 del ancho
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: isDark
                                ? const Color(0xFF59CAE8)
                                : Colors.white,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    isDark ? Colors.white : Colors.black,
                                    BlendMode.srcIn,
                                  ),
                                  child: Image.asset(
                                    'assets/icons/image.png',
                                    fit: BoxFit.contain,
                                    width: screenH * 0.05,
                                    height: screenH * 0.04,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Resto del cuadrado - 5/6 del ancho
                        Expanded(
                          flex: 5,
                          child: Container(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF353537),
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Llegó Tu informe Bancolombia 2025!',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: (screenH * 0.018).clamp(
                                      14.0,
                                      20.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Sorpréndete con tu resumen del año. Ve a Explorar, luego a Día a Día y entra a Tus informes.',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: (screenH * 0.014).clamp(
                                      12.0,
                                      16.0,
                                    ),
                                    color: isDark
                                        ? Colors.black87
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12.0),
                                Text(
                                  'Conoce más aquí.',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: (screenH * 0.014).clamp(
                                      12.0,
                                      16.0,
                                    ),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                    color: isDark ? Colors.black : Colors.white,
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
                // Píldora - se mueve con scroll
                Transform.translate(
                  offset: Offset(0, -clampedScrollOffset),
                  child: IgnorePointer(
                    child: Pill(
                      offsetX: 0.32,
                      offsetY: 0.25,
                      widthFrac: 0.58,
                      heightFrac: 0.075,
                      borderRadius: screenH * 0.05,
                      color: isDark
                          ? const Color(0xFF454648)
                          : const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
                // Segunda píldora - en la parte superior oscura, debajo del logo
                Transform.translate(
                  offset: Offset(0, -clampedScrollOffset),
                  child: IgnorePointer(
                    child: Pill(
                      offsetX: 0.75,
                      offsetY: 0.18,
                      widthFrac: 0.35,
                      heightFrac: 0.037,
                      borderRadius: screenH * 0.05,
                      color: isDark
                          ? const Color(0xFF454648)
                          : const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
                // Texto "Iniciar sesión" dentro de la segunda píldora - CLICKEABLE
                Positioned(
                  left: screenW * 0.55,
                  top: screenH * 0.162 - clampedScrollOffset,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: SizedBox(
                      width: screenW * 0.35,
                      height: screenH * 0.037,
                      child: Center(
                        child: Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontFamily: 'OpenSansSemibold',
                            fontSize: (screenH * 0.015).clamp(12.0, 16.0),
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Icono logout independiente - CLICKEABLE
                Positioned(
                  left: screenW * 0.84,
                  top: screenH * 0.162 - clampedScrollOffset,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/icons/logout.svg',
                      width: screenH * 0.035,
                      height: screenH * 0.035,
                      colorFilter: ColorFilter.mode(
                        isDark ? Colors.white : Colors.black,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                // Contenido scrolleable - se mueve con el scroll
                Transform.translate(
                  offset: Offset(0, -clampedScrollOffset),
                  child: IgnorePointer(
                    child: Stack(
                      children: [
                        // Texto "Transacciones principales"
                        Positioned(
                          left: screenW * 0.05,
                          top: screenH * 0.55,
                          child: Text(
                            'Transacciones principales',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: titleFontSize,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        // Texto "Más opciones"
                        Positioned(
                          left: screenW * 0.05,
                          top: screenH * 0.74,
                          child: Text(
                            'Más opciones',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: titleFontSize,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Carrusel de 6 cuadrados pequeños - se mueve con scroll
                Transform.translate(
                  offset: Offset(0, -clampedScrollOffset),
                  child: SmallSquareCarousel(
                    offsetY: 0.65,
                    squareWidthFrac: 0.22,
                    squareHeightFrac: 0.13,
                    gap: 10.0,
                    borderRadius: 8.0,
                    color: isDark
                        ? const Color(0xFF454648)
                        : const Color(0xFFFFFFFF),
                    isDark: isDark,
                  ),
                ),

                // Widget Más opciones - se mueve con scroll sin Transform.translate
                Positioned(
                  left: 0,
                  right: 0,
                  top: screenH * 0.78 - clampedScrollOffset,
                  child: MasOpcionesContainer(isDark: isDark),
                ),
                // ========== BARRA DE LOGOS FIJA (ENCIMA DE TODO) ==========
                // Fondo fijo detrás de los logos
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: quarterHeight * 0.4,
                  child: Container(color: const Color(0xFF333335)),
                ),
                // Logo BC
                Positioned.fill(
                  child: IgnorePointer(
                    child: TransformableSvg(
                      asset: 'assets/logo_bc.svg',
                      offsetX: 0.2,
                      offsetY: 0.03,
                      scale: 0.3,
                      colorOverride: const Color(0xFFF2F2F4),
                    ),
                  ),
                ),
                // Icono campana
                Positioned.fill(
                  child: IgnorePointer(
                    child: TransformableSvg(
                      asset: 'assets/icons/pic-bell.svg',
                      offsetX: 0.71,
                      offsetY: 0.055,
                      scale: 0.07,
                      colorOverride: const Color(0xFFF2F2F4),
                    ),
                  ),
                ),
                // Icono help
                Positioned.fill(
                  child: IgnorePointer(
                    child: TransformableSvg(
                      asset: 'assets/icons/help.svg',
                      offsetX: 0.825,
                      offsetY: 0.055,
                      scale: 0.07,
                      colorOverride: const Color(0xFFF2F2F4),
                    ),
                  ),
                ),
                // Icono whatsapp
                Positioned.fill(
                  child: IgnorePointer(
                    child: TransformableSvg(
                      asset: 'assets/icons/ic_whatsapp.svg',
                      offsetX: 0.93,
                      offsetY: 0.0565,
                      scale: 0.055,
                      colorOverride: const Color(0xFFF2F2F4),
                    ),
                  ),
                ),
                // Icono pic-lock debajo del Hola
                ClipRect(
                  clipper: _TopClipper(clipHeight: quarterHeight * 0.4),
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: IgnorePointer(
                      child: TransformableSvg(
                        asset: 'assets/icons/pic-lock.svg',
                        offsetX: 0.12,
                        offsetY: 0.245,
                        scale: 0.05,
                        colorOverride: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                // Círculo de progreso debajo del Hola
                ClipRect(
                  clipper: _TopClipper(clipHeight: quarterHeight * 0.4),
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: StaticProgressCircle(
                      offsetX: 0.12,
                      offsetY: 0.25,
                      scale: 0.06,
                      isDark: isDark,
                    ),
                  ),
                ),
                // Texto "Clave dinámica" debajo del Hola
                ClipRect(
                  clipper: _TopClipper(clipHeight: quarterHeight * 0.4),
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: StaticText(
                      text: 'Clave dinámica',
                      offsetX: 0.21,
                      offsetY: 0.22,
                      scale: 1.1,
                      isDark: isDark,
                      showShimmer: _showShimmer,
                    ),
                  ),
                ),
                // Números aleatorios debajo de Clave dinámica
                ClipRect(
                  clipper: _TopClipper(clipHeight: quarterHeight * 0.4),
                  child: Transform.translate(
                    offset: Offset(0, -clampedScrollOffset),
                    child: StaticRandomCode(
                      offsetX: 0.25,
                      offsetY: 0.25,
                      scale: 0.8,
                      isDark: isDark,
                      refreshSeconds: 40,
                      iconOffsetX: 2.0, // Separación horizontal del icono
                      iconOffsetY:
                          -0.7, // Ajuste vertical del icono (positivo = abajo, negativo = arriba)
                      iconScale: 1.0, // Tamaño del icono
                      showShimmer: _showShimmer,
                    ),
                  ),
                ),
                // Icono logout

                // Área de toque para logout (invisible, sobre el icono)
                Positioned(
                  left: screenW * 0.89,
                  top: screenH * 0.03,
                  child: GestureDetector(
                    onTap: () => _handleLogout(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.transparent,
                    ),
                  ),
                ),

                // UI de actualización disponible - diseño premium y atractivo
                if (_hasNewVersion)
                  Positioned(
                    left: screenW * 0.08,
                    right: screenW * 0.08,
                    top: screenH * 0.35,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF59CAE8).withOpacity(0.1),
                            const Color(0xFF4A90E2).withOpacity(0.05),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20.0,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF59CAE8).withOpacity(0.1),
                            blurRadius: 30.0,
                            offset: const Offset(0, 0),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2A2A2A).withOpacity(0.9)
                                  : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(20.0),
                              border: Border.all(
                                color: const Color(0xFF59CAE8).withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icono con animación y gradiente
                                Container(
                                  width: 80.0,
                                  height: 80.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF59CAE8),
                                        Color(0xFF4A90E2),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF59CAE8,
                                        ).withOpacity(0.4),
                                        blurRadius: 15.0,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.system_update_alt,
                                    size: 40.0,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20.0),

                                // Título principal con estilo premium
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          Color(0xFF59CAE8),
                                          Color(0xFF4A90E2),
                                        ],
                                      ).createShader(bounds),
                                  child: Text(
                                    '🚀 Actualización Disponible',
                                    style: TextStyle(
                                      fontFamily: 'RegularCustom',
                                      fontSize: (screenH * 0.025).clamp(
                                        18.0,
                                        24.0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12.0),

                                // Subtítulo elegante
                                Text(
                                  'Descarga la última versión con\nnuevas funciones y mejoras',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: (screenH * 0.016).clamp(
                                      13.0,
                                      17.0,
                                    ),
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24.0),

                                // Botón premium con gradiente y efectos
                                Container(
                                  width: double.infinity,
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25.0),
                                    gradient: const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF59CAE8),
                                        Color(0xFF4A90E2),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF59CAE8,
                                        ).withOpacity(0.4),
                                        blurRadius: 15.0,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _abrirLinkActualizacion,
                                      borderRadius: BorderRadius.circular(25.0),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.download_rounded,
                                              color: Colors.white,
                                              size: 22.0,
                                            ),
                                            const SizedBox(width: 8.0),
                                            Text(
                                              'Actualizar Ahora',
                                              style: TextStyle(
                                                fontFamily: 'RegularCustom',
                                                fontSize: (screenH * 0.018)
                                                    .clamp(15.0, 19.0),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12.0),

                                // Texto pequeño informativo
                                Text(
                                  'Toca para descargar desde la tienda oficial',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: (screenH * 0.012).clamp(
                                      10.0,
                                      14.0,
                                    ),
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Barra de navegación inferior
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom,
                  child: BottomNavBar(
                    height: 80.0,
                    color: isDark
                        ? const Color(0xFF282827)
                        : const Color(0xFFFFFFFF),
                    borderRadius: 0.0,
                    isDark: isDark,
                  ),
                ),
                // Animación de expansión con blur
                AnimatedBuilder(
                  animation: _expandAnimation,
                  builder: (context, child) {
                    if (_expandAnimation.value == 0) {
                      return const SizedBox.shrink();
                    }
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final bottomPadding = MediaQuery.of(context).padding.bottom;
                    final double rightOffset = screenWidth * 0.1 - 18;
                    final double qrCenterX = screenWidth - rightOffset - 25;
                    final double qrCenterY = screenHeight - 120 - bottomPadding;
                    return Positioned.fill(
                      child: IgnorePointer(
                        child: ClipPath(
                          clipper: CircleClipper(
                            progress: _expandAnimation.value,
                            center: Offset(qrCenterX, qrCenterY),
                            screenSize: Size(screenWidth, screenHeight),
                            holeRadius: 32,
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              color: Colors.black.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // 3 círculos verticales cuando está expandido con animación
                if (_isExpanded)
                  Positioned(
                    right: 20,
                    bottom:
                        95 +
                        MediaQuery.of(context).padding.bottom +
                        70, // arriba del botón QR
                    child: AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, child) {
                        // Tamaño de fuente adaptativo para el menú QR
                        final double qrMenuFontSize = (screenH * 0.02).clamp(
                          14.0,
                          18.0,
                        );
                        final double qrIconSize = (screenH * 0.055).clamp(
                          40.0,
                          50.0,
                        );

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Fila 1 (más arriba) - Tus códigos QR
                            Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _expandAnimation.value) * 100,
                              ),
                              child: Opacity(
                                opacity: _expandAnimation.value.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: _expandAnimation.value,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Tus códigos QR',
                                        style: TextStyle(
                                          fontFamily: 'RegularCustom',
                                          fontSize: qrMenuFontSize,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: qrIconSize,
                                        height: qrIconSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? const Color(0xFF454648)
                                              : const Color(0xFFFFFFFF),
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/icons/your_qr.png',
                                            width: qrIconSize * 0.55,
                                            height: qrIconSize * 0.55,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Fila 2 (medio) - Escanear código QR
                            Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _expandAnimation.value) * 60,
                              ),
                              child: Opacity(
                                opacity: _expandAnimation.value.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: _expandAnimation.value,
                                  child: GestureDetector(
                                    onTap: () {
                                      // Desactivado: no hace nada
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Escanear código QR',
                                          style: TextStyle(
                                            fontFamily: 'RegularCustom',
                                            fontSize: qrMenuFontSize,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: qrIconSize,
                                          height: qrIconSize,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark
                                                ? const Color(0xFF454648)
                                                : const Color(0xFFFFFFFF),
                                          ),
                                          child: Center(
                                            child: SvgPicture.asset(
                                              'assets/icons/escanear_qr.svg',
                                              width: qrIconSize * 0.55,
                                              height: qrIconSize * 0.55,
                                              colorFilter: ColorFilter.mode(
                                                isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Fila 3 (más abajo) - Generar código QR
                            Transform.translate(
                              offset: Offset(
                                0,
                                (1 - _expandAnimation.value) * 20,
                              ),
                              child: Opacity(
                                opacity: _expandAnimation.value.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: _expandAnimation.value,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Generar código QR',
                                        style: TextStyle(
                                          fontFamily: 'RegularCustom',
                                          fontSize: qrMenuFontSize,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: qrIconSize,
                                        height: qrIconSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isDark
                                              ? const Color(0xFF454648)
                                              : const Color(0xFFFFFFFF),
                                        ),
                                        child: Center(
                                          child: Image.asset(
                                            'assets/icons/generate_qr.png',
                                            width: qrIconSize * 0.55,
                                            height: qrIconSize * 0.55,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                // Círculo con borde amarillo encima de Ajustes - ENCIMA de la animación
                Positioned(
                  right: screenW * 0.1 - 18, // centrado sobre Ajustes
                  bottom:
                      95 +
                      MediaQuery.of(
                        context,
                      ).padding.bottom, // más arriba de la barra
                  child: GestureDetector(
                    onTap: _onQrTap,
                    child: Container(
                      width: (screenH * 0.065).clamp(45.0, 55.0),
                      height: (screenH * 0.065).clamp(45.0, 55.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF282827)
                            : const Color(0xFFFFFFFF),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: _isExpanded
                            ? Icon(
                                Icons.close,
                                size: (screenH * 0.04).clamp(26.0, 34.0),
                                color: isDark ? Colors.white : Colors.black,
                              )
                            : SvgPicture.asset(
                                'assets/icons/pic-qr-scan.svg',
                                width: (screenH * 0.04).clamp(26.0, 34.0),
                                height: (screenH * 0.04).clamp(26.0, 34.0),
                                fit: BoxFit.contain,
                                colorFilter: ColorFilter.mode(
                                  isDark ? Colors.white : Colors.black,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget que posiciona y escala un SVG libremente sobre la pantalla.
// offsetX/offsetY: relativos a pantalla (0..1), pueden ser negativos o >1 para mover fuera.
// scale: multiplicador del quarterHeight (scale = 1.0 => tamaño = quarterHeight).
class TransformableSvg extends StatelessWidget {
  final String asset;
  final double offsetX;
  final double offsetY;
  final double scale;
  // Nuevo: color opcional para forzar un filtro de color (aplica solo si no es null)
  final Color? colorOverride;

  TransformableSvg({
    Key? key,
    required this.asset,
    this.offsetX = 0.5,
    this.offsetY = 1.0,
    this.scale = 1.0,
    this.colorOverride, // agregado
  }) : super(key: key) {
    assert(offsetX.isFinite);
    assert(offsetY.isFinite);
    assert(scale > 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double screenH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;
        final double quarterH = screenH / 4;

        // Tamaño final del SVG: basado en la altura del primer cuarto y en el scale
        final double size = quarterH * 2.15 * scale;

        // Coordenadas (left, top) para centrar el SVG en offset relativo
        final double centerX = offsetX * screenW;
        final double centerY = offsetY * screenH;
        final double left = centerX - size / 2.1;
        final double top = centerY - size / 3.5;

        // Usamos Stack+Positioned para poder mover fuera de la pantalla (valores negativos permitidos)
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: size,
              height: size,
              child: SizedBox(
                width: size,
                height: size,
                // Aplicar ColorFilter si se recibió colorOverride (modo oscuro)
                child: SvgPicture.asset(
                  asset,
                  fit: BoxFit.contain,
                  colorFilter: colorOverride != null
                      ? ColorFilter.mode(colorOverride!, BlendMode.srcIn)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Nuevo widget: interactivo. Permite drag (pan) y pinch-to-zoom.
// Mantiene offsetX/offsetY en coordenadas relativas (0..1) y scale multiplicativo.
class InteractiveTransformableSvg extends StatefulWidget {
  final String asset;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;

  const InteractiveTransformableSvg({
    Key? key,
    required this.asset,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.initialScale = 1.0,
  }) : super(key: key);

  @override
  _InteractiveTransformableSvgState createState() =>
      _InteractiveTransformableSvgState();
}

class _InteractiveTransformableSvgState
    extends State<InteractiveTransformableSvg> {
  late double offsetX;
  late double offsetY;
  late double scale;

  // valores de referencia al iniciar el gesto
  late double _startOffsetX;
  late double _startOffsetY;
  late double _startScale;

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector con onScale* permite manejar drag + pinch en una sola API
    // Aplicar siempre el filtro de color al logo (modo claro y oscuro)
    final Color? forcedColor = const Color(0xFFF2F2F4);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        _startOffsetX = offsetX;
        _startOffsetY = offsetY;
        _startScale = scale;
      },
      onScaleUpdate: (details) {
        final Size screen = MediaQuery.of(context).size;
        // actualizar scale relativo (clamp para evitar valores extremos)
        double newScale = (_startScale * details.scale).clamp(0.1, 5.0);
        // details.focalPointDelta es en píxeles; convertir a coordenadas relativas
        final dxRel = details.focalPointDelta.dx / screen.width;
        final dyRel = details.focalPointDelta.dy / screen.height;
        setState(() {
          scale = newScale;
          offsetX = _startOffsetX + dxRel;
          offsetY = _startOffsetY + dyRel;
        });
      },
      child: TransformableSvg(
        asset: widget.asset,
        offsetX: offsetX,
        offsetY: offsetY,
        scale: scale,
        colorOverride: forcedColor, // pasar color siempre
      ),
    );
  }
}

// Nuevo widget: permite arrastrar sólo en X y pinchar para escalar.
class InteractiveHorizontalSvg extends StatefulWidget {
  final String asset;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;

  const InteractiveHorizontalSvg({
    Key? key,
    required this.asset,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.initialScale = 1.0,
  }) : super(key: key);

  @override
  _InteractiveHorizontalSvgState createState() =>
      _InteractiveHorizontalSvgState();
}

class _InteractiveHorizontalSvgState extends State<InteractiveHorizontalSvg> {
  late double offsetX;
  late double offsetY; // fijo: no se modifica durante el gesto
  late double scale;

  late double _startOffsetX;
  late double _startScale;

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    // Forzar color siempre al resultado 0xFFF2F2F4
    final Color forcedColor = const Color(0xFFF2F2F4);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        _startOffsetX = offsetX;
        _startScale = scale;
      },
      onScaleUpdate: (details) {
        final Size screen = MediaQuery.of(context).size;
        // Escala (clamped)
        double newScale = (_startScale * details.scale).clamp(0.05, 5.0);
        // Solo mover en X: convertir desplazamiento a relativo X
        final dxRel = details.focalPointDelta.dx / screen.width;
        setState(() {
          scale = newScale;
          offsetX = _startOffsetX + dxRel;
          // Mantener offsetY fijo (no se modifica)
        });
      },
      child: TransformableSvg(
        asset: widget.asset,
        offsetX: offsetX,
        offsetY: offsetY, // mantener Y fijo
        scale: scale,
        colorOverride: forcedColor,
      ),
    );
  }
}

// Widget: Saludo dinámico según la hora (Buenos días, Buenas tardes, Buenas noches)
class InteractiveTextPair extends StatefulWidget {
  final double initialHolaOffsetX;
  final double initialNameOffsetX;
  final double offsetY; // relativa 0..1
  final double initialScale; // escala inicial del texto

  const InteractiveTextPair({
    Key? key,
    this.initialHolaOffsetX = 0.1,
    this.initialNameOffsetX = 0.25,
    this.offsetY = 0.2,
    this.initialScale = 1.0,
  }) : super(key: key);

  @override
  _InteractiveTextPairState createState() => _InteractiveTextPairState();
}

class _InteractiveTextPairState extends State<InteractiveTextPair> {
  late double holaOffsetX;
  late double nameOffsetX;
  late double scale;
  late double _startScale;

  @override
  void initState() {
    super.initState();
    holaOffsetX = widget.initialHolaOffsetX;
    nameOffsetX = widget.initialNameOffsetX;
    scale = widget.initialScale;
  }

  // Obtener saludo según la hora
  String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 1 && hour < 12) {
      return 'Buenos días';
    } else if (hour >= 12 && hour < 19) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  // Mide ancho de texto con el estilo dado
  double _measureTextWidth(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double top = widget.offsetY * screen.height;

    // aplicar escala al tamaño base de fuente con límites adaptativos
    final double baseFontSize = (screen.height * 0.03).clamp(20.0, 30.0);
    final TextStyle style = TextStyle(
      fontFamily: 'RegularCustom',
      fontSize: baseFontSize * scale,
      color: const Color(0xFFF2F2F4),
    );

    final String greeting = _getGreeting();
    final double greetingWidth = _measureTextWidth(greeting, style);

    // coordenadas left centradas según ancho
    final double leftGreeting =
        holaOffsetX * screen.width - greetingWidth / 6.5;

    // Permitir pellizcar en toda la zona para escalar el texto
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: (details) {
        _startScale = scale;
      },
      onScaleUpdate: (details) {
        setState(() {
          scale = (_startScale * details.scale).clamp(0.5, 3.0);
        });
      },
      child: Stack(
        children: [
          // Saludo dinámico (Buenos días, Buenas tardes, Buenas noches)
          Positioned(
            left: leftGreeting,
            top: top,
            child: Text(greeting, style: style),
          ),

          // Nombre fijo (texto estático)
        ],
      ),
    );
  }
}

// Reemplazo: InteractiveSquare ahora MOVIBLE (drag) y con escala inicial controlada desde código.
// No permite cambiar ancho/alto desde la UI; sólo mover (pan) y opcionalmente pellizcar para escalar.
class InteractiveSquare extends StatefulWidget {
  final double initialOffsetX; // 0..1 relativo (centro)
  final double initialOffsetY; // 0..1 relativo (centro)
  final double widthFrac; // fracción del ancho de pantalla (base, fijo)
  final double heightFrac; // fracción de la altura de pantalla (base, fijo)
  final double initialScale; // factor inicial aplicado al tamaño
  final double initialBorderRadius;
  final Color color;

  const InteractiveSquare({
    Key? key,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.widthFrac = 0.25,
    this.heightFrac = 0.18,
    this.initialScale = 1.0,
    this.initialBorderRadius = 8.0,
    this.color = const Color(0xFF454648),
  }) : super(key: key);

  @override
  _InteractiveSquareState createState() => _InteractiveSquareState();
}

class _InteractiveSquareState extends State<InteractiveSquare> {
  late double offsetX;
  late double offsetY;
  late double scale;
  late double borderRadius;

  // refs for gestures
  late double _startOffsetX;
  late double _startOffsetY;
  late double _startScale;

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;
    borderRadius = widget.initialBorderRadius;
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    // tamaño en píxeles considerando scale multiplicativo
    final double widthPx =
        (widget.widthFrac.clamp(0.01, 1.0)) * screen.width * scale;
    final double heightPx =
        (widget.heightFrac.clamp(0.01, 1.0)) * screen.height * scale;

    // calcular left/top para centrar en offset relativo (offset representa el centro)
    double left = offsetX * screen.width - widthPx / 2;
    double top = offsetY * screen.height - heightPx / 2;

    // límites razonables para que no se pierda fuera de pantalla
    left = left.clamp(-screen.width * 0.5, screen.width * 1.5);
    top = top.clamp(-screen.height * 0.5, screen.height * 1.5);

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: widthPx,
          height: heightPx,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _startOffsetX = offsetX;
              _startOffsetY = offsetY;
              _startScale = scale;
            },
            onScaleUpdate: (details) {
              final dxRel = details.focalPointDelta.dx / screen.width;
              final dyRel = details.focalPointDelta.dy / screen.height;
              setState(() {
                // mover usando focalPointDelta (funciona como pan)
                offsetX = (_startOffsetX + dxRel).clamp(0.0, 1.0);
                offsetY = (_startOffsetY + dyRel).clamp(0.0, 1.0);
                // escalar con pinch
                scale = (_startScale * details.scale).clamp(0.01, 10.0);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(
                  borderRadius.clamp(0.0, 8888.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget Pill: píldora simple controlada solo desde código
class Pill extends StatelessWidget {
  final double offsetX;
  final double offsetY;
  final double widthFrac;
  final double heightFrac;
  final double borderRadius;
  final Color color;

  const Pill({
    super.key,
    this.offsetX = 0.5,
    this.offsetY = 0.5,
    this.widthFrac = 0.3,
    this.heightFrac = 0.05,
    this.borderRadius = 20.0,
    this.color = const Color(0xFFFFD700),
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double widthPx = widthFrac * screen.width;
    final double heightPx = heightFrac * screen.height;
    final double left = offsetX * screen.width - widthPx / 2;
    final double top = offsetY * screen.height - heightPx / 2;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: widthPx,
          height: heightPx,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget InteractiveLabel: texto movible y escalable con drag y pinch
class InteractiveLabel extends StatefulWidget {
  final String text;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final Color lightColor; // color en modo claro
  final Color darkColor; // color en modo oscuro

  const InteractiveLabel({
    super.key,
    required this.text,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.initialScale = 1.0,
    this.lightColor = Colors.black,
    this.darkColor = Colors.white,
  });

  @override
  State<InteractiveLabel> createState() => _InteractiveLabelState();
}

class _InteractiveLabelState extends State<InteractiveLabel> {
  late double offsetX;
  late double offsetY;
  late double scale;

  late double _startOffsetX;
  late double _startOffsetY;
  late double _startScale;

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? widget.darkColor : widget.lightColor;

    final double baseFontSize = (screen.height * 0.025).clamp(16.0, 24.0);
    final TextStyle style = TextStyle(
      fontFamily: 'RegularCustom',
      fontSize: baseFontSize * scale,
      color: textColor,
    );

    final double left = offsetX * screen.width;
    final double top = offsetY * screen.height;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _startOffsetX = offsetX;
              _startOffsetY = offsetY;
              _startScale = scale;
            },
            onScaleUpdate: (details) {
              final dxRel = details.focalPointDelta.dx / screen.width;
              final dyRel = details.focalPointDelta.dy / screen.height;
              setState(() {
                offsetX = (_startOffsetX + dxRel).clamp(0.0, 1.0);
                offsetY = (_startOffsetY + dyRel).clamp(0.0, 1.0);
                scale = (_startScale * details.scale).clamp(0.3, 5.0);
              });
            },
            child: Text(widget.text, style: style),
          ),
        ),
      ],
    );
  }
}

// Widget ControlledSquare: cuadrado controlado solo desde código (no interactivo)
// Permite controlar: offsetX, offsetY (posición relativa 0..1), widthFrac, heightFrac (tamaño relativo)
class ControlledSquare extends StatelessWidget {
  final double offsetX; // posición X relativa (0..1), centro del cuadrado
  final double offsetY; // posición Y relativa (0..1), centro del cuadrado
  final double widthFrac; // ancho como fracción del ancho de pantalla (0..1)
  final double heightFrac; // alto como fracción de la altura de pantalla (0..1)
  final double borderRadius;
  final Color color;

  const ControlledSquare({
    super.key,
    this.offsetX = 0.5,
    this.offsetY = 0.5,
    this.widthFrac = 0.3,
    this.heightFrac = 0.15,
    this.borderRadius = 8.0,
    this.color = const Color(0xFF454648),
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    // Calcular tamaño en píxeles
    final double widthPx = widthFrac * screen.width;
    final double heightPx = heightFrac * screen.height;

    // Calcular posición (offset representa el centro del cuadrado)
    final double left = offsetX * screen.width - widthPx / 2;
    final double top = offsetY * screen.height - heightPx / 2;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: widthPx,
          height: heightPx,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget SquareCarousel: dos cuadrados, el segundo oculto a la derecha
// Arrastra hacia la izquierda para ver el segundo cuadrado
class SquareCarousel extends StatefulWidget {
  final double offsetY;
  final double firstWidthFrac;
  final double firstHeightFrac;
  final double secondWidthFrac;
  final double secondHeightFrac;
  final double borderRadius;
  final Color color;
  final bool isDark;
  final bool ocultarSaldos; // Para ocultar/mostrar saldos
  final bool showShimmer; // Para mostrar shimmer loading
  // Parámetros del botón amarillo (independientes)
  final double buttonOffsetX; // posición X relativa al cuadrado (0..1)
  final double buttonOffsetY; // separación vertical debajo del cuadrado
  final double buttonWidthFrac; // ancho relativo al cuadrado (0..1)
  final double buttonHeightFrac; // alto relativo a la pantalla
  // Callback para notificar el progreso del drag (0 = primer cuadrado, 1 = segundo)
  final ValueChanged<double>? onDragProgress;

  const SquareCarousel({
    super.key,
    this.offsetY = 0.5,
    this.firstWidthFrac = 0.9,
    this.firstHeightFrac = 0.15,
    this.secondWidthFrac = 0.45,
    this.secondHeightFrac = 0.20,
    this.borderRadius = 12.0,
    this.color = const Color(0xFF454648),
    this.isDark = false,
    this.ocultarSaldos = false,
    this.showShimmer = false,
    // Valores por defecto del botón
    this.buttonOffsetX = 0.1,
    this.buttonOffsetY = 0.02,
    this.buttonWidthFrac = 0.8,
    this.buttonHeightFrac = 0.05,
    this.onDragProgress,
  });

  @override
  State<SquareCarousel> createState() => _SquareCarouselState();
}

class _SquareCarouselState extends State<SquareCarousel>
    with TickerProviderStateMixin {
  double dragOffset = 0.0; // offset en píxeles (negativo = hacia izquierda)
  String accountNumber = '';
  double _saldoDisponible = 0;

  // Animación de conteo
  late AnimationController _countController;
  late Animation<double> _countAnimation;
  double _displayedSaldo = 0;
  bool _wasOculto = false;

  // Animación shimmer
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _countController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _countAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _countController, curve: Curves.easeOut));
    _countController.addListener(() {
      setState(() {
        _displayedSaldo = _countAnimation.value * _saldoDisponible;
      });
    });

    // Inicializar shimmer controller
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _loadAccountNumber();
    _loadSaldo();
  }

  @override
  void didUpdateWidget(SquareCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detectar cuando cambia de oculto a visible
    if (_wasOculto && !widget.ocultarSaldos) {
      // Iniciar animación de conteo
      _countController.reset();
      _displayedSaldo = 0;
      _countController.forward();
    }
    _wasOculto = widget.ocultarSaldos;
  }

  @override
  void dispose() {
    _countController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saldoDisponible = prefs.getDouble('saldo_reserva') ?? 0;
      _displayedSaldo = _saldoDisponible; // Inicializar con el valor real
      _wasOculto = widget.ocultarSaldos; // Inicializar estado
    });
  }

  Future<void> _loadAccountNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty) {
      // Formatear el número personalizado: xxx-xxxxxx-xx
      String formatted = customAccount;
      if (customAccount.length == 11) {
        formatted =
            '${customAccount.substring(0, 3)}-${customAccount.substring(3, 9)}-${customAccount.substring(9, 11)}';
      }
      setState(() {
        accountNumber = formatted;
      });
    } else {
      _generateRandomAccountNumber();
    }
  }

  void _generateRandomAccountNumber() {
    // Generar número de cuenta random: xxx-xxxxxx-xx
    final random = math.Random();
    final part1 = random.nextInt(900) + 100; // 3 dígitos
    final part2 = random.nextInt(900000) + 100000; // 6 dígitos
    final part3 = random.nextInt(90) + 10; // 2 dígitos
    setState(() {
      accountNumber = '$part1-$part2-$part3';
    });
  }

  // Formatear número con puntos cada 3 dígitos
  String _formatNumber(double number) {
    String numStr = number.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        result = '.$result';
      }
      result = numStr[i] + result;
      count++;
    }
    return result;
  }

  // Widget shimmer para loading (idéntico al de movimiento_screen)
  Widget _buildShimmer({
    required double width,
    required double height,
    double borderRadius = 8.0,
  }) {
    final bool isDark = widget.isDark;
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height + 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: isDark
                  ? [
                      Colors.white70.withOpacity(0.3),
                      Colors.white70.withOpacity(0.5),
                      Colors.white70.withOpacity(0.3),
                    ]
                  : [
                      Colors.grey.shade400,
                      Colors.grey.shade300,
                      Colors.grey.shade400,
                    ],
              stops: [
                (_shimmerController.value - 1).clamp(0.0, 1.0),
                _shimmerController.value.clamp(0.0, 1.0),
                (_shimmerController.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    // Primer cuadrado
    final double firstW = widget.firstWidthFrac * screen.width;
    final double firstH = widget.firstHeightFrac * screen.height;
    final double leftMargin =
        screen.width * 0.05; // margen izquierdo (ajustable)
    final double firstLeft = leftMargin + dragOffset;
    final double firstTop = widget.offsetY * screen.height - firstH / 2;

    // Segundo cuadrado (a la derecha del primero, asomándose un poco)
    final double secondW = widget.secondWidthFrac * screen.width;
    final double secondH = widget.secondHeightFrac * screen.height;
    final double gap = 20.0; // separación entre cuadrados
    final double peekAmount = 10.0; // cuánto se asoma el segundo cuadrado
    final double secondLeft = firstLeft + firstW + gap - peekAmount;
    final double secondTop = widget.offsetY * screen.height - secondH / 2;

    // Límites del drag
    // El segundo cuadrado solo puede llegar hasta la mitad de la pantalla
    final double secondCenterWhenAtMid =
        screen.width / 1.25; // mitad de pantalla
    final double secondInitialCenter =
        (screen.width - firstW) / 2 + firstW + gap - peekAmount + secondW / 2;
    final double minDrag =
        -(secondInitialCenter - secondCenterWhenAtMid); // solo hasta la mitad
    final double maxDrag = 0.0; // no puede ir más a la derecha del inicio

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Primer cuadrado - con gesture detector
        Positioned(
          left: firstLeft,
          top: firstTop,
          width: firstW,
          height: firstH,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragOffset += details.delta.dx;
                dragOffset = dragOffset.clamp(minDrag, maxDrag);
                // Calcular progreso (0 = inicio, 1 = máximo arrastre)
                final progress = minDrag != 0
                    ? (dragOffset / minDrag).clamp(0.0, 1.0)
                    : 0.0;
                widget.onDragProgress?.call(progress);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Stack(
                children: [
                  // Texto "Cuenta de Ahorros" - posición y tamaño controlables
                  Positioned(
                    left: firstW * 0.05,
                    top: firstH * 0.15,
                    child: Text(
                      'Cuenta de Ahorros',
                      style: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: firstH * 0.15,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  // Número de cuenta debajo
                  Positioned(
                    left: firstW * 0.05,
                    top: firstH * 0.35,
                    child: widget.showShimmer
                        ? _buildShimmer(
                            width: firstW * 0.45,
                            height: firstH * 0.15,
                            borderRadius: 4.0,
                          )
                        : Text(
                            'Ahorros $accountNumber',
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: firstH * 0.115,
                              color: widget.isDark ? Colors.white : Colors.grey,
                            ),
                          ),
                  ),
                  // Icono chevron - posición y tamaño ajustables
                  Positioned(
                    right:
                        firstW *
                        0.05, // posición X desde la derecha (ajustable)
                    top: firstH * 0.2, // posición Y (ajustable)
                    child: Image.asset(
                      'assets/icons/pic-chevron-right.png',
                      width: firstH * 0.15, // tamaño (ajustable)
                      height: firstH * 0.15,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  // Texto "Saldo disponible" - abajo a la derecha
                  Positioned(
                    right:
                        firstW *
                        0.05, // posición X desde la derecha (ajustable)
                    bottom: firstH * 0.35, // posición Y desde abajo (ajustable)
                    child: Text(
                      'Saldo disponible',
                      style: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: firstH * 0.12, // tamaño (ajustable)
                        color: widget.isDark ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  // Valor del saldo - debajo de "Saldo disponible"
                  Positioned(
                    right: firstW * 0.05,
                    bottom: firstH * 0.12,
                    child: widget.showShimmer
                        ? _buildShimmer(
                            width: firstW * 0.35,
                            height: firstH * 0.12,
                            borderRadius: 4.0,
                          )
                        : RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.ocultarSaldos
                                      ? '\$ *****'
                                      : '\$ ${_formatNumber(_displayedSaldo)},',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: firstH * 0.18,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: widget.ocultarSaldos ? '' : '00',
                                  style: TextStyle(
                                    fontFamily: 'RegularCustom',
                                    fontSize: firstH * 0.15,
                                    color: widget.isDark
                                        ? Colors.white
                                        : Colors.black,
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
        // Segundo cuadrado - con gesture detector
        Positioned(
          left: secondLeft,
          top: secondTop,
          width: secondW,
          height: secondH,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragOffset += details.delta.dx;
                dragOffset = dragOffset.clamp(minDrag, maxDrag);
                // Calcular progreso (0 = inicio, 1 = máximo arrastre)
                final progress = minDrag != 0
                    ? (dragOffset / minDrag).clamp(0.0, 1.0)
                    : 0.0;
                widget.onDragProgress?.call(progress);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/pic-cards.svg',
                    width: secondW * 0.35,
                    height: secondW * 0.35,
                    colorFilter: ColorFilter.mode(
                      widget.isDark ? Colors.white : Colors.black,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(height: secondH * 0.02),
                  Text(
                    'Ir a todos los\nproductos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'RegularCustom',
                      fontSize: secondW * 0.12,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget YellowPillButton: botón amarillo en forma de píldora
class YellowPillButton extends StatelessWidget {
  final double offsetX; // posición X relativa (0..1)
  final double offsetY; // posición Y relativa (0..1)
  final double widthFrac; // ancho como fracción del ancho de pantalla
  final double heightFrac; // alto como fracción de la altura de pantalla
  final double borderRadius;

  const YellowPillButton({
    super.key,
    this.offsetX = 0.5,
    this.offsetY = 0.6,
    this.widthFrac = 0.8,
    this.heightFrac = 0.05,
    this.borderRadius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    final double widthPx = widthFrac * screen.width;
    final double heightPx = heightFrac * screen.height;

    final double left = offsetX * screen.width - widthPx / 2;
    final double top = offsetY * screen.height - heightPx / 0.7;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: widthPx,
          height: heightPx,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700), // amarillo
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget PageIndicator: indicador de página centrado con píldora y punto
// Parámetros ajustables: posición Y, ancho de píldora (X), tamaño del punto (Y), espaciado
// progress: 0 = primer indicador activo, 1 = segundo indicador activo
class PageIndicator extends StatelessWidget {
  final double offsetY; // posición Y relativa (0..1)
  final double pillWidth; // ancho de la píldora activa (eje X)
  final double dotSize; // tamaño del punto (eje Y y ancho del punto inactivo)
  final double spacing; // espacio entre indicadores
  final bool isDark;
  final double progress; // progreso de la animación (0 a 1)

  const PageIndicator({
    super.key,
    this.offsetY = 0.58,
    this.pillWidth = 25.0,
    this.dotSize = 8.0,
    this.spacing = 8.0,
    this.isDark = false,
    this.progress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double top = offsetY * screen.height;

    // Asegurar que progress esté en rango válido
    final double safeProgress = progress.clamp(0.0, 1.0);

    // Calcular anchos animados
    // Primer indicador: de píldora a punto (pillWidth -> dotSize)
    final double firstWidth = pillWidth - (pillWidth - dotSize) * safeProgress;
    // Segundo indicador: de punto a píldora (dotSize -> pillWidth)
    final double secondWidth = dotSize + (pillWidth - dotSize) * safeProgress;

    // Colores según tema
    // Modo oscuro: amarillo activo, gris inactivo
    // Modo claro: 0xFF454648 activo, gris inactivo
    final Color activeColor = isDark
        ? const Color(0xFFFFD700)
        : const Color(0xFF454648);
    final Color inactiveColor = Colors.grey;

    // Interpolar colores según progreso (con fallback seguro)
    final Color firstColor =
        Color.lerp(activeColor, inactiveColor, safeProgress) ?? activeColor;
    final Color secondColor =
        Color.lerp(inactiveColor, activeColor, safeProgress) ?? inactiveColor;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: top,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Primer indicador (animado)
                Container(
                  width: firstWidth,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: firstColor,
                    borderRadius: BorderRadius.circular(dotSize / 2),
                  ),
                ),
                SizedBox(width: spacing),
                // Segundo indicador (animado)
                Container(
                  width: secondWidth,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: secondColor,
                    borderRadius: BorderRadius.circular(dotSize / 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Widget SmallSquareCarousel: 6 cuadrados pequeños deslizables horizontalmente
class SmallSquareCarousel extends StatefulWidget {
  final double offsetY;
  final double squareWidthFrac;
  final double squareHeightFrac;
  final double gap;
  final double borderRadius;
  final Color color;
  final bool isDark;

  const SmallSquareCarousel({
    super.key,
    this.offsetY = 0.7,
    this.squareWidthFrac = 0.22,
    this.squareHeightFrac = 0.12,
    this.gap = 15.0,
    this.borderRadius = 8.0,
    this.color = const Color(0xFF454648),
    this.isDark = false,
  });

  @override
  State<SmallSquareCarousel> createState() => _SmallSquareCarouselState();
}

class _SmallSquareCarouselState extends State<SmallSquareCarousel> {
  double dragOffset = 0.0;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double squareW = widget.squareWidthFrac * screen.width;
    final double squareH = widget.squareHeightFrac * screen.height;
    final double top = widget.offsetY * screen.height - squareH / 2;
    final double leftMargin = screen.width * 0.05;

    // Límites del drag
    final double totalWidth = 6 * squareW + 5 * widget.gap;
    final double minDrag = -(totalWidth - screen.width + leftMargin * 2);
    final double maxDrag = 0.0;

    // Color dinámico para iconos y textos
    final Color textColor = widget.isDark ? Colors.white : Colors.black;

    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(6, (index) {
        final double left =
            leftMargin + dragOffset + index * (squareW + widget.gap);

        return Positioned(
          left: left,
          top: top,
          width: squareW,
          height: squareH,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                dragOffset += details.delta.dx;
                dragOffset = dragOffset.clamp(minDrag, maxDrag);
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.borderRadius),
              ),
              child: index == 0
                  ? GestureDetector(
                      onTap: () {
                        // Desactivado: no hace nada
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/pic_movements.svg',
                            width: squareW * 0.45,
                            height: squareW * 0.45,
                            colorFilter: ColorFilter.mode(
                              textColor,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(height: squareH * 0.08),
                          Text(
                            'Ver saldos y\nmovimientos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: squareW * 0.15,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : index == 1
                  ? Stack(
                      children: [
                        Positioned(
                          top: squareH * 0.2,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/icons/bre-b-green.svg',
                              width: squareW * 0.12,
                              height: squareW * 0.12,
                              colorFilter: ColorFilter.mode(
                                textColor,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: squareH * 0.05,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tus\nllaves',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'RegularCustom',
                                  fontSize: squareW * 0.16,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                '¡Nuevo!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'RegularCustom',
                                  fontSize: squareW * 0.15,
                                  color: Colors.green, // siempre verde
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : index == 2
                  ? GestureDetector(
                      onTap: () {
                        // Desactivado: no hace nada
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/pic_transfer.svg',
                            width: squareW * 0.5,
                            height: squareW * 0.5,
                            color: textColor,
                          ),
                          SizedBox(height: squareH * 0.06),
                          Text(
                            'Transferir\nplata',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'RegularCustom',
                              fontSize: squareW * 0.16,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : index == 3
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/pic-cards.svg',
                          width: squareW * 0.45,
                          height: squareW * 0.45,
                          colorFilter: ColorFilter.mode(
                            textColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: squareH * 0.08),
                        Text(
                          'Paga tarjetas\ny créditos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'RegularCustom',
                            fontSize: squareW * 0.15,
                            color: textColor,
                          ),
                        ),
                      ],
                    )
                  : index == 4
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/pic-invoice.svg',
                          width: squareW * 0.45,
                          height: squareW * 0.45,
                          colorFilter: ColorFilter.mode(
                            textColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: squareH * 0.08),
                        Text(
                          'Paga\nfacturas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'RegularCustom',
                            fontSize: squareW * 0.16,
                            color: textColor,
                          ),
                        ),
                      ],
                    )
                  : index == 5
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/pic-todas.svg',
                          width: squareW * 0.45,
                          height: squareW * 0.45,
                          colorFilter: ColorFilter.mode(
                            textColor,
                            BlendMode.srcIn,
                          ),
                        ),
                        SizedBox(height: squareH * 0.08),
                        Text(
                          'Ver Todos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'RegularCustom',
                            fontSize: squareW * 0.16,
                            color: textColor,
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

// Widget BottomNavBar: barra de navegación inferior
// Ocupa todo el ancho de la pantalla con altura configurable
class BottomNavBar extends StatefulWidget {
  final double height; // altura de la barra en píxeles
  final Color color; // color de fondo
  final double borderRadius; // radio de bordes (solo esquinas superiores)
  final bool isDark; // para determinar el color de los iconos
  final VoidCallback? onReturnFromAjustes; // callback al volver de ajustes
  final int?
  initialSelectedIndex; // índice inicial seleccionado (null = ninguno)

  const BottomNavBar({
    super.key,
    this.height = 80.0,
    this.color = const Color(0xFFFFFFFF),
    this.borderRadius = 0.0,
    this.isDark = false,
    this.onReturnFromAjustes,
    this.initialSelectedIndex = 0, // Por defecto 0 (Inicio)
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int? selectedIndex; // índice del icono seleccionado (null = ninguno)

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialSelectedIndex;
  }

  final List<String> icons = [
    'assets/icons/home.svg',
    'assets/icons/pic-cards.svg',
    'assets/icons/pic-explore.svg',
    'assets/icons/pic-hand-holding-document.svg',
    'assets/icons/settings.svg',
  ];

  final List<String> labels = [
    'Inicio',
    'Transacciones',
    'Explorar',
    'Trámites y\nsolicitudes',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isDark ? Colors.white : Colors.black;
    final double iconSize = (widget.height * 0.3).clamp(20.0, 28.0);
    final double fontSize = (widget.height * 0.125).clamp(9.0, 12.0);

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(widget.borderRadius),
          topRight: Radius.circular(widget.borderRadius),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(icons.length, (index) {
          final bool isSelected = selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                // Desactivado: no hace nada al hacer clic en la barra de navegación
              },
              child: Container(
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      icons[index],
                      width: iconSize,
                      height: iconSize,
                      colorFilter: ColorFilter.mode(
                        isSelected ? Colors.black : iconColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    SizedBox(height: widget.height * 0.05),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: fontSize,
                        color: isSelected ? Colors.black : iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// CustomClipper para recortar en forma de círculo expandiéndose con hueco en el centro
class CircleClipper extends CustomClipper<Path> {
  final double progress;
  final Offset center;
  final Size screenSize;
  final double holeRadius; // Radio del hueco (círculo QR)

  CircleClipper({
    required this.progress,
    required this.center,
    required this.screenSize,
    this.holeRadius = 28.0, // Radio del botón QR (50/2 + un poco de margen)
  });

  @override
  Path getClip(Size size) {
    final double maxRadius = math.sqrt(
      screenSize.width * screenSize.width +
          screenSize.height * screenSize.height,
    );
    final double currentRadius = maxRadius * progress;

    // Círculo exterior (área con blur)
    final Path outerPath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: currentRadius));

    // Círculo interior (hueco sin blur) - solo si el radio exterior es mayor
    if (currentRadius > holeRadius) {
      final Path holePath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: holeRadius));
      // Restar el hueco del círculo exterior
      return Path.combine(PathOperation.difference, outerPath, holePath);
    }

    return outerPath;
  }

  @override
  bool shouldReclip(CircleClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

// Widget InteractiveLoadingCircle: círculo de progreso movible y escalable con animación
class InteractiveLoadingCircle extends StatefulWidget {
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final bool isDark;

  const InteractiveLoadingCircle({
    super.key,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.initialScale = 0.025,
    this.isDark = false,
  });

  @override
  State<InteractiveLoadingCircle> createState() =>
      _InteractiveLoadingCircleState();
}

class _InteractiveLoadingCircleState extends State<InteractiveLoadingCircle>
    with SingleTickerProviderStateMixin {
  late double offsetX;
  late double offsetY;
  late double scale;

  late double _startOffsetX;
  late double _startOffsetY;
  late double _startScale;

  late AnimationController _progressController;
  double _progress = 0.0;
  bool _isForward = true; // true = llenando, false = vaciando

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;

    _progressController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    );

    _progressController.addListener(() {
      setState(() {
        _progress = _progressController.value;
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Cuando completa, vaciar en 2 segundos
        _isForward = false;
        _progressController.duration = const Duration(seconds: 2);
        _progressController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        // Cuando se vacía, volver a llenar en 40 segundos
        _isForward = true;
        _progressController.duration = const Duration(seconds: 40);
        _progressController.forward();
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double size = screen.height * scale;
    final double left = offsetX * screen.width - size / 2;
    final double top = offsetY * screen.height - size / 2;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _startOffsetX = offsetX;
              _startOffsetY = offsetY;
              _startScale = scale;
            },
            onScaleUpdate: (details) {
              final dxRel = details.focalPointDelta.dx / screen.width;
              final dyRel = details.focalPointDelta.dy / screen.height;
              setState(() {
                offsetX = (_startOffsetX + dxRel).clamp(0.0, 1.0);
                offsetY = (_startOffsetY + dyRel).clamp(0.0, 1.0);
                scale = (_startScale * details.scale).clamp(0.01, 0.15);
              });
            },
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: CircularProgressPainter(
                  progress: _progress,
                  strokeWidth: size * 0.06,
                  backgroundColor: Colors.grey.shade400,
                  progressColor: const Color(0xFFFFD700),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// CustomPainter para círculo de progreso que inicia desde arriba
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Fondo gris (círculo completo)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progreso amarillo (arco desde arriba)
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    const startAngle = -math.pi / 2; // Inicia desde arriba (12 en punto)

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Widget InteractiveText: texto movible y escalable
class InteractiveText extends StatefulWidget {
  final String text;
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final bool isDark;

  const InteractiveText({
    super.key,
    required this.text,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.initialScale = 1.0,
    this.isDark = false,
  });

  @override
  State<InteractiveText> createState() => _InteractiveTextState();
}

class _InteractiveTextState extends State<InteractiveText> {
  late double offsetX;
  late double offsetY;
  late double scale;

  late double _startOffsetX;
  late double _startOffsetY;
  late double _startScale;

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double fontSize = screen.height * 0.018 * scale;
    final double left = offsetX * screen.width;
    final double top = offsetY * screen.height;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _startOffsetX = offsetX;
              _startOffsetY = offsetY;
              _startScale = scale;
            },
            onScaleUpdate: (details) {
              final dxRel = details.focalPointDelta.dx / screen.width;
              final dyRel = details.focalPointDelta.dy / screen.height;
              setState(() {
                offsetX = (_startOffsetX + dxRel).clamp(0.0, 1.0);
                offsetY = (_startOffsetY + dyRel).clamp(0.0, 1.0);
                scale = (_startScale * details.scale).clamp(0.5, 3.0);
              });
            },
            child: Text(
              widget.text,
              style: TextStyle(
                fontFamily: 'RegularCustom',
                fontSize: fontSize,
                color: widget.isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget InteractiveRandomCode: código de 6 dígitos aleatorios (xxx xxx) que cambia cada X segundos
class InteractiveRandomCode extends StatefulWidget {
  final double initialOffsetX;
  final double initialOffsetY;
  final double initialScale;
  final bool isDark;
  final int refreshSeconds;
  // Parámetros del icono
  final double iconOffsetX; // Offset X relativo al texto
  final double iconOffsetY; // Offset Y relativo al texto
  final double iconScale; // Escala del icono

  const InteractiveRandomCode({
    super.key,
    this.initialOffsetX = 0.5,
    this.initialOffsetY = 0.5,
    this.initialScale = 1.0,
    this.isDark = false,
    this.refreshSeconds = 40,
    this.iconOffsetX = 0.3, // Separación horizontal del icono
    this.iconOffsetY = 0.0, // Ajuste vertical del icono
    this.iconScale = 0.8, // Tamaño del icono relativo al texto
  });

  @override
  State<InteractiveRandomCode> createState() => _InteractiveRandomCodeState();
}

class _InteractiveRandomCodeState extends State<InteractiveRandomCode> {
  late double offsetX;
  late double offsetY;
  late double scale;

  late double _startOffsetX;
  late double _startOffsetY;
  late double _startScale;

  String _code = '';
  late final math.Random _random;

  @override
  void initState() {
    super.initState();
    offsetX = widget.initialOffsetX;
    offsetY = widget.initialOffsetY;
    scale = widget.initialScale;
    _random = math.Random();
    _generateCode();
    _startTimer();
  }

  void _generateCode() {
    final first = _random.nextInt(900) + 100; // 100-999
    final second = _random.nextInt(900) + 100; // 100-999
    setState(() {
      _code = '$first $second';
    });
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: widget.refreshSeconds), () {
      if (mounted) {
        _generateCode();
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double fontSize = screen.height * 0.025 * scale;
    final double left = offsetX * screen.width;
    final double top = offsetY * screen.height;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: (details) {
              _startOffsetX = offsetX;
              _startOffsetY = offsetY;
              _startScale = scale;
            },
            onScaleUpdate: (details) {
              final dxRel = details.focalPointDelta.dx / screen.width;
              final dyRel = details.focalPointDelta.dy / screen.height;
              setState(() {
                offsetX = (_startOffsetX + dxRel).clamp(0.0, 1.0);
                offsetY = (_startOffsetY + dyRel).clamp(0.0, 1.0);
                scale = (_startScale * details.scale).clamp(0.5, 3.0);
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _code,
                  style: TextStyle(
                    fontFamily: 'RegularCustom',
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(width: fontSize * 0.3),
                Image.asset(
                  'assets/icons/pic-chevron-right.png',
                  height: fontSize * 0.8,
                  fit: BoxFit.contain,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Widget StaticProgressCircle: círculo de progreso NO interactivo (solo ajustable desde código)
class StaticProgressCircle extends StatefulWidget {
  final double offsetX;
  final double offsetY;
  final double scale;
  final bool isDark;

  const StaticProgressCircle({
    super.key,
    this.offsetX = 0.5,
    this.offsetY = 0.5,
    this.scale = 0.025,
    this.isDark = false,
  });

  @override
  State<StaticProgressCircle> createState() => _StaticProgressCircleState();
}

class _StaticProgressCircleState extends State<StaticProgressCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(seconds: 40),
      vsync: this,
    );

    _progressController.addListener(() {
      setState(() {
        _progress = _progressController.value;
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _progressController.duration = const Duration(seconds: 2);
        _progressController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _progressController.duration = const Duration(seconds: 40);
        _progressController.forward();
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double size = screen.height * widget.scale;
    final double left = widget.offsetX * screen.width - size / 2;
    final double top = widget.offsetY * screen.height - size / 2;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: CircularProgressPainter(
                progress: _progress,
                strokeWidth: size * 0.08,
                backgroundColor: Colors.grey.shade400,
                progressColor: const Color(0xFFFFD700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget StaticText: texto NO interactivo (solo ajustable desde código)
class StaticText extends StatefulWidget {
  final String text;
  final double offsetX;
  final double offsetY;
  final double scale;
  final bool isDark;
  final bool showShimmer;

  const StaticText({
    super.key,
    required this.text,
    this.offsetX = 0.5,
    this.offsetY = 0.5,
    this.scale = 1.0,
    this.isDark = false,
    this.showShimmer = false,
  });

  @override
  State<StaticText> createState() => _StaticTextState();
}

class _StaticTextState extends State<StaticText>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double fontSize = (screen.height * 0.018 * widget.scale).clamp(
      12.0,
      18.0,
    );
    final double left = widget.offsetX * screen.width;
    final double top = widget.offsetY * screen.height;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: widget.showShimmer
              ? AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      width: screen.width * 0.3,
                      height: fontSize,
                      margin: const EdgeInsets.only(left: 0.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: widget.isDark
                              ? [
                                  Colors.white70.withOpacity(0.3),
                                  Colors.white70.withOpacity(0.5),
                                  Colors.white70.withOpacity(0.3),
                                ]
                              : [
                                  Colors.grey.shade400,
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                          stops: [
                            (_shimmerController.value - 1).clamp(0.0, 1.0),
                            _shimmerController.value.clamp(0.0, 1.0),
                            (_shimmerController.value + 1).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Text(
                  widget.text,
                  style: TextStyle(
                    fontFamily: 'RegularCustom',
                    fontSize: fontSize,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
        ),
      ],
    );
  }
}

// Widget StaticRandomCode: código aleatorio NO interactivo (solo ajustable desde código)
class StaticRandomCode extends StatefulWidget {
  final double offsetX;
  final double offsetY;
  final double scale;
  final bool isDark;
  final int refreshSeconds;
  final double iconOffsetX; // Separación horizontal del icono
  final double iconOffsetY; // Ajuste vertical del icono
  final double iconScale; // Tamaño del icono
  final bool showShimmer;

  const StaticRandomCode({
    super.key,
    this.offsetX = 0.5,
    this.offsetY = 0.5,
    this.scale = 1.0,
    this.isDark = false,
    this.refreshSeconds = 40,
    this.iconOffsetX = 0.3,
    this.iconOffsetY = 0.0,
    this.iconScale = 0.8,
    this.showShimmer = false,
  });

  @override
  State<StaticRandomCode> createState() => _StaticRandomCodeState();
}

class _StaticRandomCodeState extends State<StaticRandomCode>
    with SingleTickerProviderStateMixin {
  String _code = '';
  late final math.Random _random;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _random = math.Random();
    _generateCode();
    _startTimer();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _generateCode() {
    final first = _random.nextInt(900) + 100;
    final second = _random.nextInt(900) + 100;
    setState(() {
      _code = '$first $second';
    });
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: widget.refreshSeconds), () {
      if (mounted) {
        _generateCode();
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double fontSize = (screen.height * 0.025 * widget.scale).clamp(
      16.0,
      24.0,
    );
    final double left = widget.offsetX * screen.width;
    final double top = widget.offsetY * screen.height;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: widget.showShimmer
              ? AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return Container(
                      width: screen.width * 0.2,
                      height: fontSize * 0.6,
                      margin: const EdgeInsets.only(left: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: widget.isDark
                              ? [
                                  Colors.white70.withOpacity(0.3),
                                  Colors.white70.withOpacity(0.5),
                                  Colors.white70.withOpacity(0.3),
                                ]
                              : [
                                  Colors.grey.shade400,
                                  Colors.grey.shade300,
                                  Colors.grey.shade400,
                                ],
                          stops: [
                            (_shimmerController.value - 1).clamp(0.0, 1.0),
                            _shimmerController.value.clamp(0.0, 1.0),
                            (_shimmerController.value + 1).clamp(0.0, 1.0),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _code,
                      style: TextStyle(
                        fontFamily: 'RegularCustom',
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(width: fontSize * widget.iconOffsetX),
                    Transform.translate(
                      offset: Offset(0, fontSize * widget.iconOffsetY),
                      child: Image.asset(
                        'assets/icons/pic-chevron-right.png',
                        height: fontSize * widget.iconScale,
                        fit: BoxFit.contain,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// Clipper que corta todo lo que esté por encima de clipHeight
class _TopClipper extends CustomClipper<Rect> {
  final double clipHeight;

  _TopClipper({required this.clipHeight});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, clipHeight, size.width, size.height);
  }

  @override
  bool shouldReclip(_TopClipper oldClipper) =>
      clipHeight != oldClipper.clipHeight;
}

// Clipper que corta todo lo que esté por debajo de clipHeight (desde el bottom)
class _BottomClipper extends CustomClipper<Rect> {
  final double clipHeight;

  _BottomClipper({required this.clipHeight});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width, size.height - clipHeight);
  }

  @override
  bool shouldReclip(_BottomClipper oldClipper) =>
      clipHeight != oldClipper.clipHeight;
}
