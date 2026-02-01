import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../system/index.dart';
import 'home.dart';
import 'transacciones.dart';
import 'ajuste.dart';

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
                      height: MediaQuery.of(context).padding.top + screenW * 0.02,
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
                                      (widget.nombreDestinatario ?? '').toUpperCase(),
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
                                Navigator.of(context).popUntil((route) => route.isFirst);
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
                  top: MediaQuery.of(context).padding.top +
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