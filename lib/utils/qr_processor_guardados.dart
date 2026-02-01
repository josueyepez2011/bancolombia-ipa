class QrProcessorGuardados {
  /// Extrae el nombre del QR manteniendo el formato original (espacios, mayúsculas, minúsculas)
  static String extraerNombreOriginal(String qrText) {
    final text = qrText.replaceAll('\n', ' ');

    // Lista para almacenar posibles nombres encontrados
    List<String> posiblesNombres = [];

    // 1. ESPECÍFICO PARA QR REDEBAN/MAKRO: Buscar después de "5921" (merchant name)
    RegExp patronMerchant = RegExp(r'5921([A-Z\s]{4,25})');
    final merchantMatch = patronMerchant.firstMatch(text);
    if (merchantMatch != null) {
      String nombre = merchantMatch.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // 2. ESPECÍFICO PARA QR REDEBAN: Buscar después de "0121" (otro campo de nombre)
    RegExp patron0121 = RegExp(r'0121([A-Z\s]{4,25})');
    final match0121 = patron0121.firstMatch(text);
    if (match0121 != null) {
      String nombre = match0121.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // 3. Buscar nombres con mayúsculas separadas por espacios (formato original)
    final nombreRegex = RegExp(
      r'([A-ZÁÉÍÓÚÑ]{2,}\s+[A-ZÁÉÍÓÚÑ]{2,}(?:\s+[A-ZÁÉÍÓÚÑ]{2,})?)',
    );
    for (Match match in nombreRegex.allMatches(text)) {
      String nombre = match.group(0)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // 4. Buscar patrones EMV (números seguidos de texto seguido de números)
    RegExp patronEmv = RegExp(r'\d{2,4}([A-Za-z\s][A-Za-z0-9\s]{3,30})\d{2,4}');
    for (Match match in patronEmv.allMatches(text)) {
      String nombre = match.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // 5. Buscar texto camelCase como "PuntoFrioProyectoX" (mantener formato)
    RegExp nombreCamelCase = RegExp(r'([A-Z][a-z]+(?:[A-Z][a-z0-9]*){1,4})');
    for (Match match in nombreCamelCase.allMatches(text)) {
      String nombre = match.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre) && nombre.length >= 6) {
        posiblesNombres.add(nombre);
      }
    }

    // 6. Buscar cualquier secuencia de letras entre números (con espacios)
    RegExp entreNumeros = RegExp(r'\d{2,6}([A-Za-z\s]{4,25})\d{2,6}');
    for (Match match in entreNumeros.allMatches(text)) {
      String nombre = match.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // 7. Buscar texto legible largo con espacios
    RegExp textoLegible = RegExp(r'([A-Za-z\s]{6,25})');
    for (Match match in textoLegible.allMatches(text)) {
      String nombre = match.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // 8. Buscar nombres mixtos (mayúsculas y minúsculas con espacios)
    RegExp nombreMixto = RegExp(r'([A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3})');
    for (Match match in nombreMixto.allMatches(text)) {
      String nombre = match.group(1)?.trim() ?? '';
      if (_esNombreValido(nombre)) {
        posiblesNombres.add(nombre);
      }
    }

    // Filtrar y seleccionar el mejor nombre
    if (posiblesNombres.isNotEmpty) {
      // Remover duplicados manteniendo el orden
      List<String> nombresFiltrados = [];
      Set<String> vistos = {};

      for (String nombre in posiblesNombres) {
        if (!vistos.contains(nombre.toLowerCase())) {
          nombresFiltrados.add(nombre);
          vistos.add(nombre.toLowerCase());
        }
      }

      // Ordenar por score pero mantener formato original
      nombresFiltrados.sort((a, b) {
        int scoreA = _calcularScoreNombre(a);
        int scoreB = _calcularScoreNombre(b);
        return scoreB.compareTo(scoreA);
      });

      if (nombresFiltrados.isNotEmpty) {
        // NO formatear, devolver tal como está
        return nombresFiltrados.first;
      }
    }

    return 'Negocio';
  }

  /// Valida si un nombre es válido
  static bool _esNombreValido(String nombre) {
    if (nombre.length < 3 || nombre.length > 30) return false;

    // No debe ser solo números
    if (RegExp(r'^\d+$').hasMatch(nombre)) return false;

    // No debe ser solo mayúsculas y números muy cortos (códigos)
    if (RegExp(r'^[A-Z0-9\s]+$').hasMatch(nombre) && nombre.length < 6) {
      return false;
    }

    // Debe tener al menos 2 letras
    int letras = RegExp(r'[A-Za-záéíóúñÁÉÍÓÚÑ]').allMatches(nombre).length;
    if (letras < 2) return false;

    // No debe tener demasiados números
    int numeros = RegExp(r'\d').allMatches(nombre).length;
    if (numeros > nombre.length * 0.6) return false;

    return true;
  }

  /// Calcula un score para determinar qué nombre es mejor
  static int _calcularScoreNombre(String nombre) {
    int score = 0;

    // BONUS MUY ALTO para nombres que parecen de comercios conocidos
    String nombreLower = nombre.toLowerCase();
 

    // Bonus por longitud apropiada
    if (nombre.length >= 10 && nombre.length <= 25) score += 20;
    if (nombre.length >= 8 && nombre.length <= 30) score += 15;
    if (nombre.length >= 5 && nombre.length <= 35) score += 10;

    // Bonus MUY ALTO por camelCase (mantener formato original)
    if (RegExp(r'[a-z][A-Z]').hasMatch(nombre)) score += 25;

    // Bonus por tener espacios (nombres con múltiples palabras)
    if (nombre.contains(' ')) score += 15;

    // Bonus por empezar con mayúscula
    if (RegExp(r'^[A-ZÁÉÍÓÚÑ]').hasMatch(nombre)) score += 5;

    // Bonus por tener mezcla de mayúsculas y minúsculas
    bool tieneMayusculas = RegExp(r'[A-ZÁÉÍÓÚÑ]').hasMatch(nombre);
    bool tieneMinusculas = RegExp(r'[a-záéíóúñ]').hasMatch(nombre);
    if (tieneMayusculas && tieneMinusculas) score += 15;

    // Bonus específico para palabras comunes en nombres de negocios
    if (nombreLower.contains('punto')) score += 8;
    if (nombreLower.contains('proyecto')) score += 8;
    if (nombreLower.contains('frio')) score += 8;
    if (nombreLower.contains('tienda')) score += 5;
    if (nombreLower.contains('comercial')) score += 5;
    if (nombreLower.contains('empresa')) score += 5;
    if (nombreLower.contains('negocio')) score += 5;
    if (nombreLower.contains('super')) score += 8;
    if (nombreLower.contains('market')) score += 8;

    // Penalizar nombres muy cortos o muy largos
    if (nombre.length < 4) score -= 15;
    if (nombre.length > 35) score -= 10;

    // Penalizar si tiene demasiados números
    int numeros = RegExp(r'\d').allMatches(nombre).length;
    if (numeros > nombre.length * 0.3) score -= 8;

    // Bonus por no tener números (nombres más limpios)
    if (numeros == 0) score += 5;

    // Bonus extra por tener 3 palabras (como "MAKRO FRUVER MANIZALE")
    int palabras = nombre.split(' ').length;
    if (palabras == 3) score += 10;
    if (palabras == 2) score += 5;

    return score;
  }

  /// Función principal para procesar QR guardados (mantiene formato original)
  static Map<String, dynamic> processQrGuardados(String qrText) {
    final nombreOriginal = extraerNombreOriginal(qrText);

    return {'nombre': nombreOriginal, 'qr_text': qrText};
  }
}
