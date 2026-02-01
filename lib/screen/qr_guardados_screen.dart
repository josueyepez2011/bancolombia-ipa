import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../system/index.dart';
import '../utils/qr_processor_guardados.dart';

class QrGuardadosScreen extends StatefulWidget {
  const QrGuardadosScreen({super.key});

  @override
  State<QrGuardadosScreen> createState() => _QrGuardadosScreenState();
}

class _QrGuardadosScreenState extends State<QrGuardadosScreen> {
  List<Map<String, dynamic>> _qrGuardados = [];
  bool _isLoading = false;
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _loadQrGuardados();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _loadQrGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final qrListJson = prefs.getString('qr_guardados') ?? '[]';
    setState(() {
      _qrGuardados = List<Map<String, dynamic>>.from(jsonDecode(qrListJson));
    });
  }

  Future<void> _saveQrGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('qr_guardados', jsonEncode(_qrGuardados));
  }

  Future<void> _agregarQr() async {
    // Mostrar diálogo con opciones
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final double screenW = MediaQuery.of(context).size.width;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
          title: Text(
            'Agregar código QR',
            style: TextStyle(
              fontFamily: 'OpenSansBold',
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opción Cámara
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _abrirCamara();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenW * 0.04),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF454648) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: isDark ? Colors.white : Colors.black,
                        size: screenW * 0.06,
                      ),
                      SizedBox(width: screenW * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cámara',
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.04,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Escanear QR con la cámara',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenW * 0.03),
              // Opción Imagen
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _agregarQrDesdeImagen();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(screenW * 0.04),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF454648) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.image,
                        color: isDark ? Colors.white : Colors.black,
                        size: screenW * 0.06,
                      ),
                      SizedBox(width: screenW * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Imagen',
                              style: TextStyle(
                                fontFamily: 'OpenSansBold',
                                fontSize: screenW * 0.04,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              'Seleccionar imagen de la galería',
                              style: TextStyle(
                                fontFamily: 'OpenSansRegular',
                                fontSize: screenW * 0.03,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _abrirCamara() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => _CameraScannerScreen()),
    );

    if (result != null && mounted) {
      _procesarQrTexto(result, null);
    }
  }

  Future<void> _agregarQrDesdeImagen() async {
    setState(() => _isLoading = true);

    try {
      // Importar image_picker si no está ya importado
      final ImagePicker picker = ImagePicker();
      
      // Seleccionar imagen de la galería
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && mounted) {
        // Leer la imagen como bytes
        final bytes = await image.readAsBytes();
        final imageBase64 = base64Encode(bytes);
        
        // Crear un controller temporal para analizar la imagen
        final tempController = MobileScannerController();
        
        try {
          // Intentar analizar la imagen
          final BarcodeCapture? result = await tempController.analyzeImage(image.path);
          
          if (result != null && result.barcodes.isNotEmpty) {
            final String? qrText = result.barcodes.first.rawValue;
            
            if (qrText != null && qrText.isNotEmpty) {
              // Procesar el QR igual que con la cámara
              _procesarQrTexto(qrText, imageBase64);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No se encontró un código QR válido en la imagen'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No se pudo leer el código QR de la imagen'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } finally {
          // Limpiar el controller temporal
          tempController.dispose();
        }
      }
    } catch (e) {
      debugPrint('Error al procesar imagen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la imagen. Intenta con otra imagen.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _procesarQrTexto(String qrText, String? imageBase64) {
    // Verificar si ya existe
    final existe = _qrGuardados.any((qr) => qr['qrText'] == qrText);
    if (existe) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este código QR ya está guardado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Usar QrProcessorGuardados para extraer el nombre manteniendo formato original
    final resultado = QrProcessorGuardados.processQrGuardados(qrText);
    final nombreExtraido = resultado['nombre'] ?? 'Negocio';

    debugPrint('========== QR PROCESADO CON QrProcessorGuardados ==========');
    debugPrint('Texto QR completo: $qrText');
    debugPrint('Nombre extraído (formato original): $nombreExtraido');
    debugPrint('=========================================================');

    // Mostrar diálogo con el nombre ya rellenado automáticamente
    if (mounted) {
      _mostrarDialogoNuevoQr(qrText, imageBase64 ?? '', nombreExtraido);
    }
  }

  void _mostrarDialogoNuevoQr(
    String qrText,
    String imageBase64, [
    String? nombreExtraido,
  ]) {
    final nombreController = TextEditingController();
    final cuentaController = TextEditingController();
    String tipoCuenta = 'ahorros';

    // Si se extrajo un nombre automáticamente, ponerlo en el campo
    if (nombreExtraido != null && nombreExtraido.isNotEmpty) {
      nombreController.text = nombreExtraido;
    }

    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
              title: Text(
                'Nuevo QR Bancolombia',
                style: TextStyle(
                  fontFamily: 'OpenSansBold',
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre/Alias
                    TextField(
                      controller: nombreController,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nombre del negocio',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Número de cuenta
                    TextField(
                      controller: cuentaController,
                      keyboardType: TextInputType.number,
                      maxLength: 11,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Número de cuenta (11 dígitos)',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tipo de cuenta
                    Text(
                      'Tipo de cuenta',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => tipoCuenta = 'ahorros');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tipoCuenta == 'ahorros'
                                    ? const Color(0xFFFFD700)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: tipoCuenta == 'ahorros'
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Ahorros',
                                  style: TextStyle(
                                    color: tipoCuenta == 'ahorros'
                                        ? Colors.black
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                    fontWeight: tipoCuenta == 'ahorros'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() => tipoCuenta = 'corriente');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: tipoCuenta == 'corriente'
                                    ? const Color(0xFFFFD700)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: tipoCuenta == 'corriente'
                                      ? const Color(0xFFFFD700)
                                      : Colors.grey,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  'Corriente',
                                  style: TextStyle(
                                    color: tipoCuenta == 'corriente'
                                        ? Colors.black
                                        : (isDark
                                              ? Colors.white
                                              : Colors.black),
                                    fontWeight: tipoCuenta == 'corriente'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (nombreController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ingresa un Nombre')),
                      );
                      return;
                    }
                    if (cuentaController.text.length != 11) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'El número de cuenta debe tener 11 dígitos',
                          ),
                        ),
                      );
                      return;
                    }

                    final nuevoQr = {
                      'qrText': qrText,
                      'nombre': nombreController.text.trim(),
                      'numeroCuenta': cuentaController.text.trim(),
                      'tipoCuenta': tipoCuenta,
                      'imageBase64': imageBase64,
                    };

                    setState(() {
                      _qrGuardados.add(nuevoQr);
                    });
                    _saveQrGuardados();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR guardado correctamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _eliminarQr(int index) {
    showDialog(
      context: context,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
          title: Text(
            '¿Eliminar QR?',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Se eliminará "${_qrGuardados[index]['nombre']}"',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _qrGuardados.removeAt(index);
                });
                _saveQrGuardados();
                Navigator.pop(context);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatNumeroCuenta(String numero) {
    if (numero.length != 11) return numero;
    return '${numero.substring(0, 3)}-${numero.substring(3, 9)}-${numero.substring(9)}';
  }

  void _mostrarQrFlotante(Map<String, dynamic> qr) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final imageBase64 = qr['imageBase64'] as String?;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenedor del QR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nombre
                  Text(
                    qr['nombre'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Imagen del QR
                  if (imageBase64 != null && imageBase64.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        base64Decode(imageBase64),
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.qr_code,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Info de cuenta
                  Text(
                    '${qr['tipoCuenta'] == 'ahorros' ? 'Ahorros' : 'Corriente'}',
                    style: TextStyle(
                      fontFamily: 'OpenSansRegular',
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    _formatNumeroCuenta(qr['numeroCuenta'] ?? ''),
                    style: const TextStyle(
                      fontFamily: 'OpenSansBold',
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botón cerrar
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white24
                      : Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: isDark ? Colors.white : Colors.black,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;

    return SystemAwareScaffold(
      backgroundColor: isDark
          ? const Color(0xFF2C2C2C)
          : const Color(0xFFF2F2F4),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QRs Bancolombia',
          style: TextStyle(
            fontFamily: 'OpenSansBold',
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          // Botón agregar
          Padding(
            padding: EdgeInsets.all(screenW * 0.04),
            child: GestureDetector(
              onTap: _isLoading ? null : _agregarQr,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenW * 0.04),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    else
                      const Icon(Icons.add, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? 'Cargando...' : 'Agregar código QR',
                      style: const TextStyle(
                        fontFamily: 'OpenSansBold',
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lista de QRs
          Expanded(
            child: _qrGuardados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_2,
                          size: 80,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay QRs guardados',
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega un QR de Bancolombia\npara usarlo en transferencias',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'OpenSansRegular',
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.04),
                    itemCount: _qrGuardados.length,
                    itemBuilder: (context, index) {
                      final qr = _qrGuardados[index];
                      final imageBase64 = qr['imageBase64'] as String?;
                      return GestureDetector(
                        onLongPress: () => _mostrarQrFlotante(qr),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(screenW * 0.04),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF3C3C3C)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Imagen del QR o icono por defecto
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    imageBase64 != null &&
                                        imageBase64.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.memory(
                                          base64Decode(imageBase64),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.qr_code,
                                        color: Color(0xFFFFD700),
                                        size: 22,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      qr['nombre'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansBold',
                                        fontSize: 16,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${qr['tipoCuenta'] == 'ahorros' ? 'Ahorros' : 'Corriente'} • ${_formatNumeroCuenta(qr['numeroCuenta'] ?? '')}',
                                      style: TextStyle(
                                        fontFamily: 'OpenSansRegular',
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onPressed: () => _eliminarQr(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Pantalla de escáner de cámara para QR guardados
class _CameraScannerScreen extends StatefulWidget {
  @override
  State<_CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<_CameraScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isProcessing = true;
        });
        Navigator.pop(context, code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Escanear QR',
          style: TextStyle(color: Colors.white, fontFamily: 'OpenSansBold'),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Escáner de cámara
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Overlay con marco de escaneo
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: screenW * 0.8,
              ),
            ),
          ),
          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Coloca el código QR dentro del marco',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'OpenSansRegular',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clase para el overlay del escáner
class QrScannerOverlayShape extends ShapeBorder {
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
  }) : cutOutSize = cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + borderRadius,
          rect.top,
        )
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _cutOutSize = cutOutSize < width && cutOutSize < height
        ? cutOutSize
        : (width < height ? width : height) - borderWidthSize;
    final _cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(_cutOutRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Dibujar las esquinas del marco
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path()
      // Esquina superior izquierda
      ..moveTo(_cutOutRect.left, _cutOutRect.top + borderLength)
      ..lineTo(_cutOutRect.left, _cutOutRect.top + borderRadius)
      ..quadraticBezierTo(
        _cutOutRect.left,
        _cutOutRect.top,
        _cutOutRect.left + borderRadius,
        _cutOutRect.top,
      )
      ..lineTo(_cutOutRect.left + borderLength, _cutOutRect.top)
      // Esquina superior derecha
      ..moveTo(_cutOutRect.right - borderLength, _cutOutRect.top)
      ..lineTo(_cutOutRect.right - borderRadius, _cutOutRect.top)
      ..quadraticBezierTo(
        _cutOutRect.right,
        _cutOutRect.top,
        _cutOutRect.right,
        _cutOutRect.top + borderRadius,
      )
      ..lineTo(_cutOutRect.right, _cutOutRect.top + borderLength)
      // Esquina inferior derecha
      ..moveTo(_cutOutRect.right, _cutOutRect.bottom - borderLength)
      ..lineTo(_cutOutRect.right, _cutOutRect.bottom - borderRadius)
      ..quadraticBezierTo(
        _cutOutRect.right,
        _cutOutRect.bottom,
        _cutOutRect.right - borderRadius,
        _cutOutRect.bottom,
      )
      ..lineTo(_cutOutRect.right - borderLength, _cutOutRect.bottom)
      // Esquina inferior izquierda
      ..moveTo(_cutOutRect.left + borderLength, _cutOutRect.bottom)
      ..lineTo(_cutOutRect.left + borderRadius, _cutOutRect.bottom)
      ..quadraticBezierTo(
        _cutOutRect.left,
        _cutOutRect.bottom,
        _cutOutRect.left,
        _cutOutRect.bottom - borderRadius,
      )
      ..lineTo(_cutOutRect.left, _cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
