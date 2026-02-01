class ServerConfig {
  // 🌐 CONFIGURACIÓN DEL SERVIDOR QR

  // URLs de los servidores
  static const String localServerUrl = 'http://127.0.0.1:8080';
  static const String externalServerUrl =
      'https://benevolent-marigold-8fcb65.netlify.app'; // ⬅️ TU DOMINIO DE NETLIFY

  // Configuración: true = usar Netlify, false = usar servidor local
  static const bool useExternalServer =
      true; // ⬅️ CAMBIADO A true PARA USAR NETLIFY

  // Obtener URL del servidor según configuración
  static String getServerUrl({bool isWeb = false}) {
    if (useExternalServer) {
      return externalServerUrl;
    } else if (isWeb) {
      return localServerUrl;
    } else {
      return 'http://localhost:8080';
    }
  }

  // Obtener URL completa para procesamiento de QR
  static String getProcessQrUrl({bool isWeb = false}) {
    if (useExternalServer) {
      // Netlify usa /.netlify/functions/
      return '${getServerUrl(isWeb: isWeb)}/.netlify/functions/process-qr';
    } else {
      return '${getServerUrl(isWeb: isWeb)}/process-qr';
    }
  }

  // Obtener URL completa para lectura de QR
  static String getReadQrUrl({bool isWeb = false}) {
    // Usar la misma función de procesamiento para ambos casos
    return getProcessQrUrl(isWeb: isWeb);
  }

  // Información del servidor actual
  static Map<String, dynamic> getServerInfo() {
    return {
      'type': useExternalServer ? 'external' : 'local',
      'url': useExternalServer ? externalServerUrl : 'localhost:8080',
      'supports_image_reading':
          true, // Ahora ambos soportan lectura de imágenes
      'platform': useExternalServer ? 'Netlify Functions' : 'Python Local',
    };
  }
}
