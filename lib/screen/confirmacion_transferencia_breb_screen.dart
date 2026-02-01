import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'dart:convert';
import '../system/index.dart';
import 'transfer_completed_screen.dart';

class ConfirmacionTransferenciaBrebScreen extends StatefulWidget {
  final String valorTransferencia;
  final String numeroCelular;
  final String numeroCuenta;
  final String nombreDestinatario;
  final bool esNequi;
  final String tipoCuentaDestino;
  final String llaveBreB; // Nueva variable para la llave Bre-B

  const ConfirmacionTransferenciaBrebScreen({
    Key? key,
    required this.valorTransferencia,
    required this.numeroCelular,
    this.numeroCuenta = '000 - 000000 - 00',
    this.nombreDestinatario = '',
    this.esNequi = false,
    this.tipoCuentaDestino = '',
    this.llaveBreB = '', // Valor por defecto
  }) : super(key: key);

  @override
  State<ConfirmacionTransferenciaBrebScreen> createState() =>
      _ConfirmacionTransferenciaBrebScreenState();
}

class _ConfirmacionTransferenciaBrebScreenState
    extends State<ConfirmacionTransferenciaBrebScreen> {
  bool _showCircle = false;
  String _numeroCuentaPersonalizado = '';
  final TextEditingController _llaveController = TextEditingController();
  bool _mostrarCampoLlave = false;
  String _llaveActual = ''; // Nueva variable para almacenar la llave actual

  @override
  void initState() {
    super.initState();
    debugPrint('=== INICIANDO ConfirmacionTransferenciaBrebScreen ===');
    debugPrint('valorTransferencia: ${widget.valorTransferencia}');
    debugPrint('numeroCelular: ${widget.numeroCelular}');
    debugPrint('nombreDestinatario: ${widget.nombreDestinatario}');
    debugPrint('llaveBreB: ${widget.llaveBreB}');
    debugPrint('Esta es la pantalla específica para Bre-B');

    // Inicializar la llave actual
    _llaveActual = widget.llaveBreB;

    // Si la llave está vacía o es "no encontrada", mostrar el campo
    if (widget.llaveBreB.isEmpty || widget.llaveBreB == 'no encontrada') {
      _mostrarCampoLlave = true;
      debugPrint('Llave no encontrada, mostrando campo de entrada');
    } else {
      debugPrint('Llave encontrada: ${widget.llaveBreB}');
      // Si hay llave, ponerla en el controller para editarla
      _llaveController.text = widget.llaveBreB;
    }

    _loadNumeroCuenta();
  }

  // Función para alternar la visibilidad del campo de llave
  void _toggleCampoLlave() {
    setState(() {
      _mostrarCampoLlave = !_mostrarCampoLlave;
      if (_mostrarCampoLlave) {
        debugPrint('Mostrando campo para editar llave');
        // Si hay llave existente, ponerla en el campo para editarla
        if (_llaveActual.isNotEmpty && _llaveActual != 'no encontrada') {
          _llaveController.text = _llaveActual;
        }
      } else {
        debugPrint('Ocultando campo de llave');
      }
    });
  }

  // Función para actualizar la llave
  void _actualizarLlave() {
    final nuevaLlave = _llaveController.text.trim();
    if (nuevaLlave.isNotEmpty) {
      debugPrint('Actualizando llave a: $nuevaLlave');
      // Actualizar la llave actual y ocultar el campo
      setState(() {
        _llaveActual = nuevaLlave; // Actualizar la llave que se muestra
        _mostrarCampoLlave = false;
      });

      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Llave actualizada: $nuevaLlave'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Mostrar error si está vacío
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese una llave válida'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _llaveController.dispose();
    super.dispose();
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
    debugPrint('=== CONSTRUYENDO ConfirmacionTransferenciaBrebScreen ===');
    debugPrint('Título debería ser: Transferir Bre-b');

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
                // Título - AQUÍ ES DONDE SE VE "Transferir Bre-b"
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transferir Bre-b',
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
                        GestureDetector(
                          onLongPress: () {
                            debugPrint(
                              'Long press detectado en código de negocio',
                            );
                            _toggleCampoLlave();
                          },
                          child: Container(
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
                                // Mostrar llave o campo de entrada
                                if (!_mostrarCampoLlave &&
                                    _llaveActual.isNotEmpty &&
                                    _llaveActual != 'no encontrada')
                                  Text(
                                    _llaveActual,
                                    style: TextStyle(
                                      fontFamily: 'OpenSansBold',
                                      fontSize: screenW * 0.042,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  )
                                else
                                  // Campo flotante para ingresar la llave
                                  Container(
                                    width: double.infinity,
                                    height:
                                        screenW *
                                        0.4, // Aumentar altura para el botón
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF454648)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenW * 0.03,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Línea en la mitad
                                        Positioned(
                                          left: screenW * 0.04,
                                          right: screenW * 0.04,
                                          top: screenW * 0.2,
                                          child: Center(
                                            child: Divider(
                                              height: 1,
                                              thickness: 1,
                                              color: const Color.fromARGB(
                                                255,
                                                255,
                                                208,
                                                0,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Texto "Ingrese el código de la llave"
                                        Positioned(
                                          left: screenW * 0.06,
                                          right: screenW * 0.06,
                                          top: screenW * 0.06,
                                          child: Text(
                                            'Ingrese el código de la llave',
                                            style: TextStyle(
                                              fontFamily: 'OpenSansRegular',
                                              fontSize: screenW * 0.035,
                                              color: isDark
                                                  ? const Color.fromARGB(
                                                      255,
                                                      255,
                                                      254,
                                                      254,
                                                    )
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ),
                                        // Icono de llave y campo de texto
                                        Positioned(
                                          left: screenW * 0.06,
                                          right: screenW * 0.06,
                                          top:
                                              screenW *
                                              0.12, // Ajustar posición
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/icons/pic-key.svg',
                                                width: screenW * 0.07,
                                                height: screenW * 0.07,
                                                colorFilter: ColorFilter.mode(
                                                  isDark
                                                      ? Colors.white
                                                      : Colors.black,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                              SizedBox(width: screenW * 0.02),
                                              Expanded(
                                                child: TextField(
                                                  controller: _llaveController,
                                                  keyboardType:
                                                      TextInputType.text,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'OpenSansRegular',
                                                    fontSize: screenW * 0.05,
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.black,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        border:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                        hintText:
                                                            'Ej: 0091461102',
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Botón OK debajo de la línea
                                        Positioned(
                                          left: screenW * 0.06,
                                          right: screenW * 0.06,
                                          bottom: screenW * 0.0,
                                          child: ElevatedButton(
                                            onPressed: _actualizarLlave,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    255,
                                                    208,
                                                    0,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      screenW * 0.02,
                                                    ),
                                              ),
                                              elevation: 0,
                                              minimumSize: Size(
                                                double.infinity,
                                                screenW * 0.1,
                                              ),
                                            ),
                                            child: Text(
                                              'OK',
                                              style: TextStyle(
                                                fontFamily: 'OpenSansBold',
                                                fontSize: screenW * 0.04,
                                                color: Colors.black,
                                              ),
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
                                          numeroCelular: _llaveActual.isNotEmpty
                                              ? _llaveActual
                                              : widget.numeroCelular,
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
