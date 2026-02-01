import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:math' as math;
import '../system/index.dart';
import 'home.dart';
import 'transacciones.dart';
import 'ajuste.dart';

class TransferConfirmationScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String numeroCuenta;
  final String nombreDestinatario;
  final bool esNequi;
  final bool esBreB; // Nuevo parámetro para identificar QR Bre-B
  final String tipoCuentaDestino;
  final String? llaveBreB; // Nuevo parámetro para la llave Bre-B

  const TransferConfirmationScreen({
    super.key,
    required this.valorTransferencia,
    this.numeroCelular = '',
    this.numeroCuenta = '000 - 000000 - 00',
    this.nombreDestinatario = '',
    this.esNequi = false,
    this.esBreB = false, // Por defecto false
    this.tipoCuentaDestino = '',
    this.llaveBreB,
  });

  @override
  State<TransferConfirmationScreen> createState() =>
      _TransferConfirmationScreenState();
}

class _TransferConfirmationScreenState
    extends State<TransferConfirmationScreen> {
  final TextEditingController _destinatarioController = TextEditingController();
  List<Map<String, String>> _llaves = []; // Lista de llaves guardadas

  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el texto para actualizar el botón
    _destinatarioController.addListener(() {
      setState(() {});
    });
    _loadLlaves();
  }

  Future<void> _loadLlaves() async {
    final prefs = await SharedPreferences.getInstance();
    final llavesString = prefs.getStringList('llaves_guardadas') ?? [];
    setState(() {
      _llaves = llavesString.map((llave) {
        final parts = llave.split('|');
        return {
          'nombre': parts.length > 0 ? parts[0] : '',
          'banco': parts.length > 1 ? parts[1] : '',
          'destinatario': parts.length > 2 ? parts[2] : '',
        };
      }).toList();
    });
  }

  bool _isLlaveRegistrada(String nombreLlave) {
    return _llaves.any(
      (llave) => llave['nombre']?.toLowerCase() == nombreLlave.toLowerCase(),
    );
  }

  void _mostrarAvisoLlaveNoRegistrada() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C1810) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFF9800).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de advertencia
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // Título
                Text(
                  'Llave no registrada',
                  style: TextStyle(
                    fontFamily: 'OpenSansBold',
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF2C1810),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'La llave ingresada no se encuentra registrada en tus ajustes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                // Botón cerrar
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF9800).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _continuarTransferencia() {
    final nombreLlave = _destinatarioController.text.trim();

    if (nombreLlave.isEmpty) return;

    if (!_isLlaveRegistrada(nombreLlave)) {
      _mostrarAvisoLlaveNoRegistrada();
      return;
    }

    // Buscar la llave para obtener el nombre del destinatario
    final llave = _llaves.firstWhere(
      (llave) => llave['nombre']?.toLowerCase() == nombreLlave.toLowerCase(),
    );

    final nombreDestinatario = llave['destinatario'] ?? 'Destinatario';

    // Si la llave está registrada, navegar a la pantalla de confirmación QR
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmacionTransferenciaQrScreen(
          valorTransferencia: widget.valorTransferencia,
          numeroCelular:
              nombreLlave, // Pasar el nombre de la llave como "número"
          numeroCuenta: '000 - 000000 - 00',
          nombreDestinatario:
              nombreDestinatario, // Nombre del destinatario de la llave
          esNequi: false,
          tipoCuentaDestino: 'ahorros',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _destinatarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        resizeToAvoidBottomInset:
            false, // Evita que el teclado desplace el layout
        backgroundColor: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF2F2F4),
        body: Column(
          children: [
            // Primera parte - Mismo color que la pantalla anterior con header
            Expanded(
              flex: 1, // 1/5 de la pantalla
              child: Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF353537) : Colors.white,
                child: Column(
                  children: [
                    _buildHeader(context, screenW, screenH, isDark),
                    SizedBox(height: screenH * 0.03),
                    // Título principal
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¿A quién le llega?',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: screenW * 0.06,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Segunda parte - Contenedor con campo de texto
            Expanded(
              flex: 1, // 1/5 de la pantalla
              child: Container(
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFF2F2F4),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                  child: Column(
                    children: [
                      SizedBox(height: screenH * 0.02),
                      // Contenedor con signo de pesos y campo de texto
                      Container(
                        width: double.infinity,
                        height: screenW * 0.3,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(screenW * 0.03),
                        ),
                        child: Stack(
                          children: [
                            // Línea en la mitad (más abajo)
                            Positioned(
                              left: screenW * 0.04,
                              right: screenW * 0.04,
                              top: screenW * 0.15,
                              bottom: screenW * 0.08,
                              child: Center(
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: const Color.fromARGB(255, 255, 208, 0),
                                ),
                              ),
                            ),
                            // Texto "Ingrese el nombre de la llave" encima del icono de llave (más abajo)
                            Positioned(
                              left: screenW * 0.06,
                              right: screenW * 0.06,
                              top: screenW * 0.06,
                              child: Text(
                                'Ingrese el nombre de la llave',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.035,
                                  color: isDark
                                      ? const Color.fromARGB(255, 255, 254, 254)
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            // Icono de llave y campo de texto (más abajo)
                            Positioned(
                              left: screenW * 0.06,
                              right: screenW * 0.06,
                              bottom: screenW * 0.115,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/pic-key.svg',
                                    width: screenW * 0.07,
                                    height: screenW * 0.07,
                                    colorFilter: ColorFilter.mode(
                                      isDark ? Colors.white : Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  SizedBox(width: screenW * 0.02),
                                  Expanded(
                                    child: TextField(
                                      controller: _destinatarioController,
                                      keyboardType: TextInputType.text,
                                      style: TextStyle(
                                        fontFamily: 'OpenSansRegular',
                                        fontSize: screenW * 0.05,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Texto "Nombre de la llave registrada en ajustes" debajo de la línea (más abajo)
                            Positioned(
                              left: screenW * 0.06,
                              right: screenW * 0.06,
                              bottom: screenW * 0.05,
                              child: Text(
                                'Nombre de la llave registrada en ajustes',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.035,
                                  color: isDark
                                      ? Colors.grey[500]
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Tercera parte
            Expanded(
              flex: 1, // 1/5 de la pantalla
              child: Container(
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFF2F2F4),
              ),
            ),
            // Cuarta parte
            Expanded(
              flex: 1, // 1/5 de la pantalla
              child: Container(
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFF2F2F4),
              ),
            ),
            // Quinta parte - Contenedor con botón y paso 2 de 3
            Expanded(
              flex: 1, // 1/5 de la pantalla
              child: Container(
                width: double.infinity,
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFF2F2F4),
                child: Column(
                  children: [
                    // Espacio expandible
                    const Expanded(child: SizedBox()),
                    // Contenedor con botón y paso 2 de 3
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenW * 0.05,
                        vertical: screenW * 0.04,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF454648) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Botón Continuar
                          ElevatedButton(
                            onPressed: _destinatarioController.text.isNotEmpty
                                ? _continuarTransferencia
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(
                                double.infinity,
                                screenW * 0.12,
                              ),
                              backgroundColor:
                                  _destinatarioController.text.isNotEmpty
                                  ? const Color(0xFFFFD700)
                                  : Colors.transparent,
                              foregroundColor:
                                  _destinatarioController.text.isNotEmpty
                                  ? Colors.black
                                  : (isDark ? Colors.white : Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                                side: BorderSide(
                                  color: _destinatarioController.text.isNotEmpty
                                      ? const Color(0xFFFFD700)
                                      : (isDark ? Colors.white : Colors.grey),
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Continuar',
                              style: TextStyle(
                                fontFamily: 'OpenSansSemibold',
                                fontSize: screenW * 0.045,
                                color: _destinatarioController.text.isNotEmpty
                                    ? Colors.black
                                    : (isDark ? Colors.white : Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(height: screenW * 0.03),
                          // Paso 2 de 3 con línea dividida en 3 partes
                          Row(
                            children: [
                              Text(
                                'Paso 3 de 3',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.035,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(width: screenW * 0.03),
                              // Línea dividida en 3 partes
                              Row(
                                children: [
                                  // Parte 1 - Amarilla
                                  Container(
                                    width: screenW * 0.65 / 3,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(2),
                                        bottomLeft: Radius.circular(2),
                                      ),
                                    ),
                                  ),
                                  // Parte 2 - Amarilla
                                  Container(
                                    width: screenW * 0.65 / 3,
                                    height: 4,
                                    color: const Color(0xFFFFD700),
                                  ),
                                  // Parte 3 - Gris
                                  Container(
                                    width: screenW * 0.65 / 3,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD700),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(2),
                                        bottomRight: Radius.circular(2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    double screenW,
    double screenH,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenW * 0.04,
        vertical: screenH * 0.02,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón Volver
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Transform.rotate(
                  angle: 3.14159, // 180 grados en radianes
                  child: Image.asset(
                    'assets/icons/pic-chevron-right.png',
                    width: screenW * 0.045,
                    height: screenW * 0.045,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(width: screenW * 0.02),
                Text(
                  'Volver',
                  style: TextStyle(
                    fontFamily: 'OpenSansRegular',
                    fontSize: screenW * 0.045,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Logo CIB con línea vertical y icono breb
          Padding(
            padding: EdgeInsets.only(right: screenW * 0.05),
            child: Row(
              children: [
                // Icono breb al lado izquierdo
                SvgPicture.asset(
                  'assets/icons/bre-b-green.svg',
                  width: screenW * 0.035,
                  height: screenW * 0.035,
                  colorFilter: ColorFilter.mode(
                    isDark ? Colors.white : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: screenW * 0.02),
                // Línea vertical
                Container(
                  width: 1,
                  height: screenW * 0.05,
                  color: isDark ? Colors.white : Colors.black,
                ),
                SizedBox(width: screenW * 0.02),
                // Icono CIB
                SvgPicture.asset(
                  'assets/icons/CIB.svg',
                  width: screenW * 0.05,
                  height: screenW * 0.05,
                  colorFilter: isDark
                      ? const ColorFilter.mode(
                          Color(0xFFF2F2F4),
                          BlendMode.srcIn,
                        )
                      : null,
                ),
              ],
            ),
          ),
          // Continuar
          Row(
            children: [
              Text(
                'Continuar',
                style: TextStyle(
                  fontFamily: 'OpenSansRegular',
                  fontSize: screenW * 0.04,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(width: screenW * 0.01),
              Image.asset(
                'assets/icons/pic-chevron-right.png',
                width: screenW * 0.045,
                height: screenW * 0.045,
                color: isDark ? Colors.white : Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============ CONFIRMACION TRANSFERENCIA QR SCREEN ============
class ConfirmacionTransferenciaQrScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String numeroCuenta;
  final String nombreDestinatario;
  final bool esNequi;
  final String tipoCuentaDestino;

  const ConfirmacionTransferenciaQrScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCelular,
    this.numeroCuenta = '000 - 000000 - 00',
    this.nombreDestinatario = '',
    this.esNequi = false,
    this.tipoCuentaDestino = '',
  }) : super(key: key);

  @override
  State<ConfirmacionTransferenciaQrScreen> createState() =>
      _ConfirmacionTransferenciaQrScreenState();
}

class _ConfirmacionTransferenciaQrScreenState
    extends State<ConfirmacionTransferenciaQrScreen> {
  bool _showCircle = false;
  String _numeroCuentaPersonalizado = '';

  @override
  void initState() {
    super.initState();
    _loadNumeroCuenta();
  }

  Future<void> _loadNumeroCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuentaPersonalizado =
            '${customAccount.substring(0, 3)}-${customAccount.substring(3, 9)}-${customAccount.substring(9, 11)}';
      });
    }
  }

  String get _displayNumeroCuenta => _numeroCuentaPersonalizado.isNotEmpty
      ? _numeroCuentaPersonalizado
      : widget.numeroCuenta;

  // Función para formatear nombre con asteriscos cada 3 letras
  String _formatearNombreConAsteriscos(String nombre) {
    if (nombre.isEmpty) return '';

    // Separar por espacios para procesar cada palabra
    List<String> palabras = nombre.split(' ');
    List<String> palabrasFormateadas = [];

    for (String palabra in palabras) {
      if (palabra.isEmpty) continue;

      // Convertir cada palabra: primera mayúscula, resto minúscula
      String palabraFormateada = palabra.toLowerCase();
      palabraFormateada =
          palabraFormateada[0].toUpperCase() + palabraFormateada.substring(1);

      if (palabraFormateada.length <= 3) {
        // Si la palabra tiene 3 letras o menos, agregar *** al final
        palabrasFormateadas.add(palabraFormateada + '***');
      } else {
        // Si tiene más de 3 letras, tomar las primeras 3 y agregar ***
        palabrasFormateadas.add(palabraFormateada.substring(0, 3) + '***');
      }
    }

    return palabrasFormateadas.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Variables para el círculo centrado
    final double circleSize = screenW * 0.4;
    final double circlePosX = screenW / 2;
    final double circlePosY = screenH / 2;
    final double lottieSize = circleSize * 0.6;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF2F2F4),
        body: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.04,
                    vertical: screenH * 0.01,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: 3.14159,
                              child: Image.asset(
                                'assets/icons/pic-chevron-right.png',
                                width: screenW * 0.045,
                                height: screenW * 0.045,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(width: screenW * 0.02),
                            Text(
                              'Volver',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.045,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: screenW * 0.05),
                        child: SvgPicture.asset(
                          'assets/icons/CIB.svg',
                          width: screenW * 0.08,
                          height: screenW * 0.08,
                          colorFilter: isDark
                              ? const ColorFilter.mode(
                                  Color(0xFFF2F2F4),
                                  BlendMode.srcIn,
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(
                              'Transferir',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.04,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            SizedBox(width: screenW * 0.02),
                            Image.asset(
                              'assets/icons/pic-chevron-right.png',
                              width: screenW * 0.045,
                              height: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenH * 0.02),
                // Título
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.esNequi
                            ? 'Transferir Bre-b'
                            : 'Transferir Bre-b',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.035,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: screenW * 0.01),
                      Text(
                        'Verifica la transferencia',
                        style: TextStyle(
                          fontFamily: 'OpenSansBold',
                          fontSize: screenW * 0.06,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenH * 0.02),
                // Contenido scrolleable
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: screenW * 0.1,
                                height: screenW * 0.1,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF9AD1C9,
                                  ).withOpacity(0.3),
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline,
                                  size: screenW * 0.06,
                                  color: const Color(0xFF9AD1C9),
                                ),
                              ),
                              SizedBox(width: screenW * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tus transferencias a Nequi y cuentas Bancolombia no tienen costo.',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: screenW * 0.035,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: screenH * 0.01),
                                    Text(
                                      'A otros bancos te cuesta \$7.300 + IVA cada una. Si tienes Plan Oro o Plan Pensión 035, tienes transferencias sin costo.',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansRegular',
                                        fontSize: screenW * 0.03,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                    SizedBox(height: screenH * 0.01),
                                    Text(
                                      'Descubre tu plan',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansRegular',
                                        fontSize: screenW * 0.035,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.03),
                        // ¿Cuánto vas a pagar?
                        Text(
                          '¿Cuánto vas a pagar?',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenH * 0.015),
                        // Valor a pagar
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Valor a pagar',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.03,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: screenH * 0.005),
                                  Text(
                                    '\$ ${widget.valorTransferencia}',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.05,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Cambiar',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.035,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: screenW * 0.05,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.01),
                        // Costo del pago
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Costo del pago',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: screenH * 0.005),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$ 0,',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.045,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: screenW * 0.005,
                                    ),
                                    child: Text(
                                      '00',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: screenW * 0.03,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.03),
                        // ¿A quien le llega?
                        Text(
                          '¿A quien le llega?',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenH * 0.015),
                        // Primer contenedor - Punto de venta
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Punto de venta',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansRegular',
                                        fontSize: screenW * 0.03,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: screenH * 0.005),
                                    Text(
                                      widget.nombreDestinatario.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: screenW * 0.045,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Cambiar',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.035,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: screenW * 0.01),
                                  Icon(
                                    Icons.chevron_right,
                                    size: screenW * 0.05,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.01),
                        // Segundo contenedor - Código de negocio
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatearNombreConAsteriscos(
                                  widget.nombreDestinatario,
                                ),
                                style: TextStyle(
                                  fontFamily: 'OpenSansBold',
                                  fontSize: screenW * 0.045,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenH * 0.0),
                              Text(
                                'Código de negocio',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: screenH * 0.00),
                              Text(
                                widget.numeroCelular,
                                style: TextStyle(
                                  fontFamily: 'OpenSansBold',
                                  fontSize: screenW * 0.042,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.03),
                        // ¿De dónde sale la plata?
                        Text(
                          '¿De dónde sale la plata?',
                          style: TextStyle(
                            fontFamily: 'OpenSansBold',
                            fontSize: screenW * 0.045,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        SizedBox(height: screenH * 0.015),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cuenta de ahorros',
                                style: TextStyle(
                                  fontFamily: 'OpenSansBold',
                                  fontSize: screenW * 0.04,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenH * 0.005),
                              Text(
                                'Ahorros',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                _displayNumeroCuenta,
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.03,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.02),
                      ],
                    ),
                  ),
                ),
                // Botones
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: screenH * 0.06,
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() => _showCircle = true);

                            // Descontar el saldo disponible
                            final prefs = await SharedPreferences.getInstance();
                            final saldoActual =
                                prefs.getDouble('saldo_reserva') ?? 0;

                            // Limpiar el valor: remover puntos, comas y espacios
                            String valorLimpio = widget.valorTransferencia
                                .replaceAll('.', '')
                                .replaceAll(',', '')
                                .replaceAll(' ', '');

                            final valorTransferido =
                                double.tryParse(valorLimpio) ?? 0;
                            final nuevoSaldo = saldoActual - valorTransferido;

                            // Guardar el nuevo saldo
                            await prefs.setDouble(
                              'saldo_reserva',
                              nuevoSaldo > 0 ? nuevoSaldo : 0,
                            );

                            // Debug para verificar
                            print('Saldo actual: $saldoActual');
                            print('Valor a transferir: $valorTransferido');
                            print(
                              'Nuevo saldo: ${nuevoSaldo > 0 ? nuevoSaldo : 0}',
                            );

                            // Guardar el movimiento en movimientos_bancolombia
                            final movimientosJson =
                                prefs.getString('movimientos_bancolombia') ??
                                '[]';
                            final List<dynamic> movimientos = jsonDecode(
                              movimientosJson,
                            );
                            final nuevoMovimiento = {
                              'fecha': DateTime.now().toIso8601String(),
                              'descripcion': 'Pago Bre-b',
                              'valor': valorTransferido,
                              'tipo': 'debito',
                            };
                            movimientos.insert(0, nuevoMovimiento);
                            await prefs.setString(
                              'movimientos_bancolombia',
                              jsonEncode(movimientos),
                            );

                            print(
                              'Movimiento guardado: Pago Bre-b por \$${valorTransferido.toInt()}',
                            );

                            // Simular proceso de transferencia
                            Future.delayed(const Duration(seconds: 3), () {
                              if (mounted) {
                                setState(() => _showCircle = false);
                                // Navegar a la pantalla simple
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TransferCompletedScreen(
                                          valorTransferido: valorTransferido
                                              .toInt()
                                              .toString(),
                                          nombreDestinatario:
                                              widget.nombreDestinatario,
                                          numeroCelular: widget.numeroCelular,
                                        ),
                                  ),
                                );
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Transferir plata',
                            style: TextStyle(
                              fontFamily: 'OpenSansSemibold',
                              fontSize: screenW * 0.045,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenH * 0.015),
                      SizedBox(
                        width: double.infinity,
                        height: screenH * 0.06,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontFamily: 'OpenSansSemibold',
                              fontSize: screenW * 0.045,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenH * 0.02),
                    ],
                  ),
                ),
              ],
            ),
            // Fondo borroso cuando se muestra el círculo
            if (_showCircle)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
            // Círculo centrado con loading
            if (_showCircle)
              Positioned(
                left: circlePosX - circleSize / 2,
                top: circlePosY - circleSize / 2,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF353537) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: lottieSize * 0.5,
                          height: lottieSize * 0.5,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.white : const Color(0xFFFFDD00),
                            ),
                          ),
                        ),
                        SizedBox(height: lottieSize * 0.1),
                        Text(
                          'Validando\nclave dinámica',
                          style: TextStyle(
                            fontSize: lottieSize * 0.12,
                            color: isDark ? Colors.white : Colors.black87,
                            fontFamily: 'OpenSansRegular',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Pantalla simple con solo color de fondo
class TransferCompletedScreen extends StatefulWidget {
  final String? valorTransferido;
  final String? nombreDestinatario;
  final String? numeroCelular;

  const TransferCompletedScreen({
    super.key,
    this.valorTransferido,
    this.nombreDestinatario,
    this.numeroCelular,
  });

  @override
  State<TransferCompletedScreen> createState() =>
      _TransferCompletedScreenState();
}

class _TransferCompletedScreenState extends State<TransferCompletedScreen> {
  String _numeroCuentaPersonalizado = '';
  ScrollController _scrollController = ScrollController();
  String _numeroComprobante = '';

  @override
  void initState() {
    super.initState();
    _loadNumeroCuenta();
    _generateVoucherNumber();
  }

  // Función para generar número de comprobante aleatorio con letras
  void _generateVoucherNumber() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = math.Random();
    _numeroComprobante = List.generate(
      9,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  Future<void> _loadNumeroCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty && customAccount.length == 11) {
      setState(() {
        _numeroCuentaPersonalizado = customAccount;
      });
    } else {
      // Generar número aleatorio como en home.dart si no hay número personalizado
      final random = math.Random();
      final part1 = random.nextInt(900) + 100; // 3 dígitos
      final part2 = random.nextInt(900000) + 100000; // 6 dígitos
      final part3 = random.nextInt(90) + 10; // 2 dígitos
      setState(() {
        _numeroCuentaPersonalizado = '$part1$part2$part3';
      });
    }
  }

  // Función para obtener los últimos 4 dígitos de la cuenta
  String get _ultimos4Digitos {
    if (_numeroCuentaPersonalizado.isEmpty) {
      return '*0000'; // Fallback si aún no se ha cargado
    }
    // Extraer solo los dígitos del número de cuenta
    final limpio = _numeroCuentaPersonalizado.replaceAll(RegExp(r'\D'), '');
    if (limpio.length >= 4) {
      return '*${limpio.substring(limpio.length - 4)}';
    }
    return '*0000'; // Fallback
  }

  void _compartirComprobante() {
    // Implementar funcionalidad de compartir
    // Por ahora solo mostramos un mensaje
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidad de compartir próximamente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required double screenW,
    required bool isDark,
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            icon,
            width: screenW * 0.06,
            height: screenW * 0.06,
            colorFilter: ColorFilter.mode(
              isDark ? Colors.white : Colors.black,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(height: screenW * 0.02),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'OpenSansRegular',
              fontSize: screenW * 0.03,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF2F2F4),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                color: isDark
                    ? const Color(0xFF2C2C2C)
                    : const Color(0xFFF2F2F4),
                child: Column(
                  children: [
                    SizedBox(
                      height:
                          MediaQuery.of(context).padding.top + screenW * 0.02,
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: screenW * 0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Icono breb al lado izquierdo
                          SvgPicture.asset(
                            'assets/icons/bre-b-green.svg',
                            width: screenW * 0.035,
                            height: screenW * 0.035,
                            colorFilter: ColorFilter.mode(
                              isDark ? Colors.white : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: screenW * 0.02),
                          // Línea vertical
                          Container(
                            width: 1,
                            height: screenW * 0.05,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          SizedBox(width: screenW * 0.02),
                          // Icono CIB
                          SvgPicture.asset(
                            'assets/icons/CIB.svg',
                            width: screenW * 0.05,
                            height: screenW * 0.05,
                            colorFilter: isDark
                                ? const ColorFilter.mode(
                                    Color(0xFFF2F2F4),
                                    BlendMode.srcIn,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenW * 0.1),
                    // Cuadrado con dientes de sierra y contenido
                    Stack(
                      children: [
                        // Fondo con dientes de sierra
                        CustomPaint(
                          size: Size(screenW * 0.9, screenW * 1.6),
                          painter: ZigzagBorderPainter(
                            color: isDark
                                ? const Color(0xFF454648)
                                : Colors.white,
                          ),
                        ),
                        // Contenido dentro del cuadrado
                        Container(
                          width: screenW * 0.9,
                          padding: EdgeInsets.all(screenW * 0.06),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: screenW * 0.0),
                              // Círculo con check
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: screenW * 0.15,
                                    height: screenW * 0.12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF64DAB7),
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    'assets/icons/check.svg',
                                    width: screenW * 0.07,
                                    height: screenW * 0.07,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.black,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenW * 0.04),
                              // Transferencia exitosa
                              Text(
                                '¡Transferencia exitosa!',
                                style: TextStyle(
                                  fontFamily: 'OpenSansBold',
                                  fontSize: screenW * 0.055,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenW * 0.02),
                              // Comprobante No.
                              Text(
                                'Comprobante No. $_numeroComprobante',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.04,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenW * 0.01),
                              // Fecha/hora
                              Text(
                                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.04,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Línea punteada
                              CustomPaint(
                                size: Size(screenW * 0.85, 2),
                                painter: DottedLinePainter(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenW * 0.04),
                              // Valor de la transferencia
                              Text(
                                'Valor de la transferencia',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.035,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenW * 0.02),
                              // Valor en grande
                              Text(
                                '\$ ${widget.valorTransferido ?? "0"}',
                                style: TextStyle(
                                  fontFamily: 'OpenSansBold',
                                  fontSize: screenW * 0.07,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Costo de la transferencia
                              Text(
                                'Costo de la transferencia',
                                style: TextStyle(
                                  fontFamily: 'OpenSansRegular',
                                  fontSize: screenW * 0.03,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenW * 0.01),
                              // Costo
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '\$ 0,',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: screenW * 0.045,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '00',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: screenW * 0.035,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Segunda línea punteada
                              CustomPaint(
                                size: Size(screenW * 0.85, 2),
                                painter: DottedLinePainter(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              SizedBox(height: screenW * 0.04),
                              // ¿A quién le llegó la plata?
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '¿A quién le llegó la plata?',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansBold',
                                    fontSize: screenW * 0.045,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Enviado a - Nombre
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enviado a',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.04,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      (widget.nombreDestinatario ?? '')
                                          .toUpperCase(),
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: screenW * 0.04,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Código de negocio
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Código de negocio',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.04,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    widget.numeroCelular ?? '',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.042,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenW * 0.04),
                              // ¿De dónde salió?
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '¿De dónde salió?',
                                  style: TextStyle(
                                    fontFamily: 'OpenSansBold',
                                    fontSize: screenW * 0.045,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Cuenta de Ahorros - Ahorros *6671
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cuenta de Ahorros',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.04,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Ahorros',
                                        style: TextStyle(
                                          fontFamily: 'OpenSansBold',
                                          fontSize: screenW * 0.04,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        _ultimos4Digitos,
                                        style: TextStyle(
                                          fontFamily: 'OpenSansBold',
                                          fontSize: screenW * 0.04,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: screenW * 0.03),
                              // Nuevo saldo disponible
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Nuevo saldo disponible',
                                    style: TextStyle(
                                      fontFamily: 'OpenSansRegular',
                                      fontSize: screenW * 0.04,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: screenW * 0.08,
                                        height: screenW * 0.08,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.grey[600]!
                                                : Colors.grey[400]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.visibility_outlined,
                                          size: screenW * 0.045,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(width: screenW * 0.02),
                                      Text(
                                        '\$ *****',
                                        style: TextStyle(
                                          fontFamily: 'OpenSansBold',
                                          fontSize: screenW * 0.04,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenW * 0.05),
                    // Botones de acción en un solo contenedor
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenW * 0.04),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF454648)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(screenW * 0.03),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionButton(
                              context: context,
                              screenW: screenW,
                              isDark: isDark,
                              icon: 'assets/icons/pic-share.svg',
                              label: 'Compartir',
                              onTap: _compartirComprobante,
                            ),
                            _buildActionButton(
                              context: context,
                              screenW: screenW,
                              isDark: isDark,
                              icon: 'assets/icons/pic-qr-scan.svg',
                              label: 'Escanear\ncódigo QR',
                              onTap: () {},
                            ),
                            _buildActionButton(
                              context: context,
                              screenW: screenW,
                              isDark: isDark,
                              icon: 'assets/icons/pic-send-money.svg',
                              label: 'Hacer otra\ntransferencia',
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: screenW * 0.1,
                    ), // Espacio al final para scroll
                  ],
                ),
              ),
            ),
            // Trazo superpuesto en la parte superior
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                double scrollOffset = _scrollController.hasClients
                    ? _scrollController.offset
                    : 0.0;
                return Positioned(
                  top:
                      MediaQuery.of(context).padding.top +
                      screenW * 0.00 -
                      (scrollOffset * 1.0),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.3,
                      child: SvgPicture.asset(
                        'assets/trazos/bre-b-trazo.svg',
                        width: screenW * 0.3,
                        height: screenW * 0.3,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: _TransferCompletedBottomNavBar(isDark: isDark),
      ),
    );
  }
}

// Painter personalizado para crear bordes en zigzag
class ZigzagBorderPainter extends CustomPainter {
  final Color color;

  ZigzagBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Configuración de los dientes
    final double zigzagHeight = 8.0;
    final double zigzagWidth = 12.0;
    final int zigzagCount = (size.width / zigzagWidth).floor();
    final double actualZigzagWidth = size.width / zigzagCount;

    // Comenzar desde la esquina superior izquierda
    path.moveTo(0, zigzagHeight);

    // Crear dientes de sierra en la parte superior
    for (int i = 0; i < zigzagCount; i++) {
      final double x = i * actualZigzagWidth;
      path.lineTo(x + actualZigzagWidth / 2, 0);
      path.lineTo(x + actualZigzagWidth, zigzagHeight);
    }

    // Lado derecho
    path.lineTo(size.width, size.height - zigzagHeight);

    // Crear dientes de sierra en la parte inferior (invertidos)
    for (int i = zigzagCount; i > 0; i--) {
      final double x = i * actualZigzagWidth;
      path.lineTo(x - actualZigzagWidth / 2, size.height);
      path.lineTo(x - actualZigzagWidth, size.height - zigzagHeight);
    }

    // Lado izquierdo
    path.lineTo(0, zigzagHeight);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Barra de navegación para TransferCompletedScreen
class _TransferCompletedBottomNavBar extends StatefulWidget {
  final bool isDark;

  const _TransferCompletedBottomNavBar({required this.isDark});

  @override
  State<_TransferCompletedBottomNavBar> createState() =>
      _TransferCompletedBottomNavBarState();
}

class _TransferCompletedBottomNavBarState
    extends State<_TransferCompletedBottomNavBar> {
  int selectedIndex = -1; // Ninguno seleccionado

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
    final Color bgColor = widget.isDark
        ? const Color(0xFF282827)
        : const Color(0xFFFFFFFF);
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: bgColor,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(icons.length, (index) {
            final bool isSelected = index == selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (index == 0) {
                    // Inicio
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  } else if (index == 1) {
                    // Transacciones
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransaccionesScreen(),
                      ),
                    );
                  } else if (index == 4) {
                    // Ajustes
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AjusteScreen(),
                      ),
                    );
                  } else {
                    // Otros índices (2 y 3) no hacen nada por ahora
                    setState(() {
                      selectedIndex = index;
                    });
                  }
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
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          isSelected ? Colors.black : iconColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'RegularCustom',
                          fontSize: 10,
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
      ),
    );
  }
}

// Painter personalizado para crear línea punteada
class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const double dashWidth = 8.0;
    const double dashSpace = 6.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
