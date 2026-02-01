// Ejemplo de prueba para el extractor de llave RBM
// Este archivo es solo para demostración y puede ser eliminado

import 'lib/utils/qr_processor.dart';

void main() {
  // QR real proporcionado por el usuario
  final qrReal = '0002015502010102115802CO5910SR  BURGER49250103RBM0014CO.COM.RBM.RED903001060000010016CO.COM.RBM.TRXID80270103APP0016CO.COM.RBM.CANAL91460124XMG84lQBfQRXTqbS99FYvdwI0014CO.COM.RBM.SEC81250102010015CO.COM.RBM.CIVA601211001 BOGOTA8223010100014CO.COM.RBM.IVA5031011000905311910013CO.COM.RBM.CU6105110018324010100015CO.COM.RBM.BASE6232030300007030000802000901A110363184250102010015CO.COM.RBM.CINC520400008523010100014CO.COM.RBM.INC530317064200002ES0110SR  BURGER63046A87';
  
  // Ejemplos adicionales de QR con diferentes formatos RBM
  final ejemplosQr = [
    // QR real del usuario (llave esperada: 0090531191)
    qrReal,
    
    // Ejemplo 2: Formato con CU (Cliente)
    '00020101021226580014CO.COM.RBM.CU05109876543210590012Restaurant6009Bogota6204123463041234',
    
    // Ejemplo 3: Formato con REF (Referencia)
    '00020101021226580014CO.COM.RBM.REF05105555666677590012Tienda ABC6009Bogota6204123463041234',
    
    // Ejemplo 4: QR sin RBM (debería retornar 'no encontrada')
    '00020101021226580014NEQUI.COM590012Juan Perez6009Bogota6204123463041234',
  ];

  print('=== PRUEBAS DEL EXTRACTOR DE LLAVE RBM MEJORADO ===\n');

  for (int i = 0; i < ejemplosQr.length; i++) {
    final qr = ejemplosQr[i];
    final llave = QrProcessor.extraerLlaveRbm(qr);
    
    print('Ejemplo ${i + 1}:');
    if (i == 0) {
      print('QR REAL del usuario (llave esperada: 0090531191)');
      print('QR: ${qr.substring(0, 100)}...');
      print('Llave extraída: $llave');
      print('✅ ${llave == '0090531191' ? 'CORRECTO' : 'INCORRECTO'}');
    } else {
      print('QR: ${qr.substring(0, 50)}...');
      print('Llave extraída: $llave');
    }
    print('---\n');
  }

  // Prueba completa del procesador con el QR real
  print('=== PRUEBA COMPLETA DEL PROCESADOR CON QR REAL ===\n');
  final resultado = QrProcessor.processQrLocal(qrReal);
  
  print('QR real: ${qrReal.substring(0, 100)}...');
  print('Resultado completo:');
  resultado.forEach((key, value) {
    print('  $key: $value');
  });
}