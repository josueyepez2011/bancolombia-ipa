import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/index.dart';
import 'transfer_confirmation_screen.dart';

class BreBTransferScreen extends StatefulWidget {
  const BreBTransferScreen({super.key});

  @override
  State<BreBTransferScreen> createState() => _BreBTransferScreenState();
}

class _BreBTransferScreenState extends State<BreBTransferScreen> {
  String _numeroCuenta = '';
  double _saldoHome = 0;
  double _saldoDisponible = 0;
  bool _ocultarSaldo = false; // Estado para ocultar/mostrar saldo
  bool _isEnabled = true; // Estado para habilitar/deshabilitar botón
  final TextEditingController _valorController = TextEditingController();

  void _onValorChanged(String value) {
    // Actualizar el estado para que el botón cambie de apariencia
    setState(() {
      // Solo actualizar el estado, sin modificar el valor
    });
  }

  // Función para formatear números con puntos cada 3 dígitos
  String _formatNumber(double number) {
    String numStr = number.toInt().toString();
    String result = '';
    int count = 0;
    for (int i = numStr.length - 1; i >= 0; i--) {
      count++;
      result = numStr[i] + result;
      if (count % 3 == 0 && i != 0) {
        result = '.$result';
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _loadNumeroCuenta();
    _loadSaldoHome();
    // Asegurar que el controlador esté vacío
    _valorController.clear();
  }

  Future<void> _loadSaldoHome() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _saldoHome = prefs.getDouble('saldo_reserva') ?? 0;
      _saldoDisponible = _saldoHome; // Inicializar saldo disponible
    });
  }

  Future<void> _loadNumeroCuenta() async {
    final prefs = await SharedPreferences.getInstance();
    final customAccount = prefs.getString('numero_cuenta_personalizado') ?? '';
    if (customAccount.isNotEmpty) {
      // Formatear el número personalizado: xxx - xxxxxx - xx
      String formatted = customAccount;
      if (customAccount.length == 11) {
        formatted =
            '${customAccount.substring(0, 3)} - ${customAccount.substring(3, 9)} - ${customAccount.substring(9, 11)}';
      }
      setState(() {
        _numeroCuenta = formatted;
      });
    } else {
      setState(() {
        _numeroCuenta = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final double screenH = MediaQuery.of(context).size.height;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ErrorHandlerScreen(
      child: SystemAwareScaffold(
        backgroundColor: isDark
            ? const Color(0xFF2C2C2C)
            : const Color(0xFFF2F2F4),
        body: Column(
          children: [
            // Primera parte - Header con color específico
            Container(
              height: screenH * 0.25, // 25% de la pantalla
              width: double.infinity,
              color: isDark ? const Color(0xFF353537) : Colors.white,
              child: Column(
                children: [
                  _buildHeader(context, screenW, screenH, isDark),
                  SizedBox(height: screenH * 0.05),
                  // Título principal
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '¿Cuánto vas a transferir?',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.058,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenH * 0.02),
                  // Subtítulos y número de cuenta
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Número de cuenta',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.035,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Text(
                              _numeroCuenta.isEmpty
                                  ? '00 - 000000 - 00'
                                  : _numeroCuenta,
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.045,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Saldo disponible',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.035,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            SizedBox(height: screenH * 0.005),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _ocultarSaldo = !_ocultarSaldo;
                                    });
                                  },
                                  child: Icon(
                                    _ocultarSaldo
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: screenW * 0.04,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                SizedBox(width: screenW * 0.02),
                                _ocultarSaldo
                                    ? Text(
                                        '••••••',
                                        style: TextStyle(
                                          fontFamily: 'OpenSansBold',
                                          fontSize: screenW * 0.045,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      )
                                    : RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  '\$ ${_formatNumber(_saldoHome)}',
                                              style: TextStyle(
                                                fontFamily: 'OpenSansBold',
                                                fontSize: screenW * 0.045,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ',00',
                                              style: TextStyle(
                                                fontFamily: 'OpenSansBold',
                                                fontSize:
                                                    screenW *
                                                    0.035, // Más pequeño
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          ],
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
            // Espacio pequeño
            SizedBox(height: screenH * 0.03),
            // Contenedor con signo de pesos y campo de texto
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
              child: Container(
                width: double.infinity,
                height: screenW * 0.3,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF454648) : Colors.white,
                  borderRadius: BorderRadius.circular(screenW * 0.03),
                ),
                child: Stack(
                  children: [
                    // Línea en la mitad
                    Positioned(
                      left: screenW * 0.04,
                      right: screenW * 0.04,
                      top: 30,
                      bottom: 0,
                      child: Center(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: const Color.fromARGB(255, 255, 208, 0),
                        ),
                      ),
                    ),
                    // Texto "Ingrese el valor a transferir" encima del signo de pesos
                    Positioned(
                      left: screenW * 0.06,
                      right: screenW * 0.08,
                      top: screenW * 0.06,
                      child: Text(
                        'Ingrese el valor a transferir',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.035,
                          color: isDark
                              ? const Color.fromARGB(255, 255, 254, 254)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                    // Signo de pesos y campo de texto
                    Positioned(
                      left: screenW * 0.06,
                      right: screenW * 0.06,
                      bottom: screenW * 0.10,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '\$',
                            style: TextStyle(
                              fontFamily: 'OpenSansRegular',
                              fontSize: screenW * 0.07,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(width: screenW * 0.02),
                          Expanded(
                            child: TextField(
                              controller: _valorController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  // Solo actualizar el estado para el botón
                                });
                              },
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.05,
                                color: isDark ? Colors.white : Colors.black,
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
                    // Texto "Máximo $ 3.000.000 por día" debajo de la línea
                    Positioned(
                      left: screenW * 0.06,
                      right: screenW * 0.06,
                      bottom: screenW * 0.06,
                      child: Text(
                        'Máximo \$ 3.000.000 por día',
                        style: TextStyle(
                          fontFamily: 'OpenSansRegular',
                          fontSize: screenW * 0.035,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Espacio expandible
            const Expanded(child: SizedBox()),
            // Contenedor con botón y paso 1 de 1
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
                    onPressed: () {
                      if (_valorController.text.isNotEmpty) {
                        // Obtener el valor ingresado y convertir a número
                        final valorTexto = _valorController.text
                            .replaceAll('.', '')
                            .replaceAll(',', '');
                        final valorIngresado = double.tryParse(valorTexto) ?? 0;

                        // Validar que el valor no sea mayor al saldo disponible
                        if (valorIngresado > _saldoHome) {
                          // Mostrar alerta de saldo insuficiente
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Saldo insuficiente'),
                              content: Text(
                                'El valor ingresado (\$${_formatNumber(valorIngresado)}) supera tu saldo disponible (\$${_formatNumber(_saldoHome)}).',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Entendido'),
                                ),
                              ],
                            ),
                          );
                          return;
                        }

                        // Si el saldo es suficiente, continuar con la transferencia
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransferConfirmationScreen(
                              valorTransferencia: _valorController.text,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, screenW * 0.12),
                      backgroundColor: _valorController.text.isNotEmpty
                          ? const Color(0xFFFFD700)
                          : Colors.transparent,
                      foregroundColor: _valorController.text.isNotEmpty
                          ? Colors.black
                          : (isDark ? Colors.white : Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                          color: _valorController.text.isNotEmpty
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
                        color: _valorController.text.isNotEmpty
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
                        'Paso 2 de 3',
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
                              color: Colors.grey[400],
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
            padding: EdgeInsets.only(right: screenW * 0.02),
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
