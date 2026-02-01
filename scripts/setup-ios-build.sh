#!/bin/bash

# Script para configurar el build de iOS en GitHub Actions
# Ejecutar desde la raíz del proyecto

echo "🍎 Configurando build de iOS para GitHub Actions..."

# Verificar que estamos en la raíz del proyecto Flutter
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Ejecuta este script desde la raíz del proyecto Flutter"
    exit 1
fi

# Crear directorio de scripts si no existe
mkdir -p scripts

echo "📋 Información necesaria para configurar GitHub Secrets:"
echo ""
echo "1. IOS_CERTIFICATE_BASE64:"
echo "   - Exporta tu certificado de desarrollo desde Keychain Access como .p12"
echo "   - Convierte a base64: base64 -i certificado.p12 | pbcopy"
echo ""
echo "2. IOS_CERTIFICATE_PASSWORD:"
echo "   - La contraseña que usaste al exportar el certificado .p12"
echo ""
echo "3. IOS_PROVISIONING_PROFILE_BASE64:"
echo "   - Descarga tu perfil de aprovisionamiento desde Apple Developer Portal"
echo "   - Convierte a base64: base64 -i perfil.mobileprovision | pbcopy"
echo ""
echo "4. KEYCHAIN_PASSWORD:"
echo "   - Genera una contraseña segura aleatoria para el keychain temporal"
echo ""

# Verificar si el ExportOptions.plist existe
if [ -f "ios/Runner/ExportOptions.plist" ]; then
    echo "✅ ExportOptions.plist encontrado"
else
    echo "❌ ExportOptions.plist no encontrado"
fi

# Mostrar información del Bundle ID actual
if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
    BUNDLE_ID=$(grep -o 'PRODUCT_BUNDLE_IDENTIFIER = [^;]*' ios/Runner.xcodeproj/project.pbxproj | head -1 | cut -d' ' -f3)
    echo "📱 Bundle ID actual: $BUNDLE_ID"
    echo "   Asegúrate de que coincida con tu perfil de aprovisionamiento"
else
    echo "⚠️  No se pudo determinar el Bundle ID"
fi

echo ""
echo "🔧 Próximos pasos:"
echo "1. Configura los 4 secretos en GitHub: Settings → Secrets and variables → Actions"
echo "2. Actualiza ios/Runner/ExportOptions.plist con tu Team ID y nombre del perfil"
echo "3. Ejecuta el workflow desde GitHub Actions"
echo ""
echo "📚 Para más detalles, consulta IOS_BUILD_SETUP.md"