# Comandos útiles para build de iOS

## 🏗️ Comandos locales de Flutter

```bash
# Limpiar build anterior
flutter clean

# Obtener dependencias
flutter pub get

# Generar código
flutter packages pub run build_runner build --delete-conflicting-outputs

# Analizar código
flutter analyze

# Ejecutar tests
flutter test

# Build iOS (sin firmar)
flutter build ios --release --no-codesign

# Build iOS (firmado)
flutter build ios --release
```

## 🍎 Comandos de Xcode

```bash
# Desde la carpeta ios/
cd ios

# Limpiar build de Xcode
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner

# Build y archivar
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath ../build/bancolombia_v3.xcarchive \
           archive

# Exportar IPA
xcodebuild -exportArchive \
           -archivePath ../build/bancolombia_v3.xcarchive \
           -exportOptionsPlist Runner/ExportOptions.plist \
           -exportPath ../build/ipa
```

## 🔍 Comandos de verificación

```bash
# Verificar certificados instalados
security find-identity -v -p codesigning

# Verificar perfiles de aprovisionamiento
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Ver información de un perfil
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision

# Verificar Bundle ID del proyecto
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

## 🐛 Comandos de debug

```bash
# Ver logs detallados de build
flutter build ios --release --verbose

# Ver información del dispositivo iOS conectado
flutter devices

# Ejecutar en simulador específico
flutter run -d "iPhone 15 Pro"

# Ver logs del simulador
xcrun simctl spawn booted log stream --predicate 'process == "Runner"'
```

## 📦 Comandos de GitHub Actions (local testing)

```bash
# Instalar act para ejecutar GitHub Actions localmente
# https://github.com/nektos/act

# Ejecutar workflow localmente (requiere Docker)
act -j build-ios-unsigned

# Ejecutar con secretos
act -j build-ios --secret-file .secrets
```

## 🔧 Comandos de mantenimiento

```bash
# Actualizar Flutter
flutter upgrade

# Verificar configuración de Flutter
flutter doctor -v

# Limpiar cache de pub
flutter pub cache clean

# Reparar permisos de Xcode
sudo xcode-select --install

# Verificar versión de Xcode
xcodebuild -version
```

## 📱 Comandos para distribución

```bash
# Subir a TestFlight (requiere Application Loader o Transporter)
xcrun altool --upload-app -f "bancolombia_v3.ipa" -u "tu@email.com" -p "app-specific-password"

# Verificar IPA antes de subir
xcrun altool --validate-app -f "bancolombia_v3.ipa" -u "tu@email.com" -p "app-specific-password"
```

## 🎯 Comandos de automatización

```bash
# Script completo de build
#!/bin/bash
flutter clean
flutter pub get
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build ios --release

# Si todo sale bien, crear IPA
cd ios
xcodebuild -workspace Runner.xcworkspace \
           -scheme Runner \
           -configuration Release \
           -destination generic/platform=iOS \
           -archivePath ../build/bancolombia_v3.xcarchive \
           archive

xcodebuild -exportArchive \
           -archivePath ../build/bancolombia_v3.xcarchive \
           -exportOptionsPlist Runner/ExportOptions.plist \
           -exportPath ../build/ipa

echo "✅ IPA generado en build/ipa/"
```