# Configuración para Build de iOS en GitHub Actions

## 🚀 Workflows Disponibles

### 1. `build-and-deploy-ios.yml` (Recomendado)
- Build completo con opción de firmado
- Se ejecuta en push a main/master y tags
- Permite ejecución manual con selección de tipo de build
- Crea releases automáticos para tags

### 2. `build-ios.yml` 
- Build firmado completo con IPA
- Requiere certificados configurados

### 3. `build-ios-unsigned.yml`
- Build sin firmar para testing
- No requiere certificados

## 🔐 Secretos requeridos en GitHub (solo para builds firmados)

Para que el workflow funcione correctamente, necesitas configurar los siguientes secretos en tu repositorio de GitHub:

### 1. Certificado de desarrollo iOS
- **IOS_CERTIFICATE_BASE64**: Tu certificado .p12 convertido a base64
- **IOS_CERTIFICATE_PASSWORD**: La contraseña de tu certificado .p12

### 2. Perfil de aprovisionamiento
- **IOS_PROVISIONING_PROFILE_BASE64**: Tu perfil de aprovisionamiento .mobileprovision convertido a base64

### 3. Keychain temporal
- **KEYCHAIN_PASSWORD**: Una contraseña segura para el keychain temporal (puedes generar una aleatoria)

## 📋 Cómo obtener y convertir los archivos

### Paso 1: Obtener el certificado .p12
1. Abre Keychain Access en tu Mac
2. Busca tu certificado de desarrollo iOS
3. Exporta como .p12 con una contraseña segura

### Paso 2: Obtener el perfil de aprovisionamiento
1. Ve a Apple Developer Portal
2. Descarga tu perfil de aprovisionamiento (.mobileprovision)

### Paso 3: Convertir a base64
```bash
# Para el certificado
base64 -i tu_certificado.p12 | pbcopy

# Para el perfil de aprovisionamiento
base64 -i tu_perfil.mobileprovision | pbcopy
```

### Paso 4: Configurar secretos en GitHub
1. Ve a tu repositorio en GitHub
2. Settings → Secrets and variables → Actions
3. Agrega los 4 secretos mencionados arriba

## ⚙️ Configuración adicional requerida

### Actualizar ExportOptions.plist
Edita el archivo `ios/Runner/ExportOptions.plist` y reemplaza:
- `YOUR_TEAM_ID` con tu Team ID de Apple Developer
- `YOUR_PROVISIONING_PROFILE_NAME` con el nombre de tu perfil de aprovisionamiento
- Verifica que el Bundle ID coincida con tu perfil de aprovisionamiento

### Verificar Bundle ID
Asegúrate de que el Bundle ID en tu proyecto Xcode coincida con el de tu perfil de aprovisionamiento.

## 🏗️ Tipos de build disponibles

El workflow está configurado para `app-store`. Si necesitas otros tipos, puedes cambiar el `method` en ExportOptions.plist:
- `app-store`: Para subir a App Store
- `ad-hoc`: Para distribución interna
- `enterprise`: Para distribución empresarial
- `development`: Para desarrollo y testing

## 🚀 Ejecución del workflow

### Automática:
- Push a las ramas main, master, o develop
- Pull requests a esas ramas
- Push de tags (crea release automático)

### Manual:
1. Ve a la pestaña Actions en GitHub
2. Selecciona "Build and Deploy iOS"
3. Click en "Run workflow"
4. Elige el tipo de build (unsigned/signed)

## 📦 Artifacts generados

- **Build unsigned**: Disponible por 7 días
- **Build signed (IPA)**: Disponible por 30 días
- **Releases**: Para tags, se crea un release con el IPA adjunto

## 🔧 Troubleshooting

### Error de certificados
- Verifica que los secretos estén configurados correctamente
- Asegúrate de que el certificado no haya expirado
- Verifica que el perfil de aprovisionamiento sea válido

### Error de Bundle ID
- Verifica que el Bundle ID en ExportOptions.plist coincida con tu perfil
- Asegúrate de que el perfil de aprovisionamiento incluya tu Bundle ID

### Error de Team ID
- Obtén tu Team ID desde Apple Developer Portal
- Actualiza ExportOptions.plist con el Team ID correcto

## 📱 Configuración del proyecto

### Bundle ID actual
El proyecto está configurado con Bundle ID dinámico. Verifica en:
- `ios/Runner.xcodeproj/project.pbxproj`
- Apple Developer Portal

### Permisos requeridos
El proyecto incluye permisos para:
- Cámara (image_picker)
- Galería de fotos
- Autenticación biométrica
- Acceso a archivos

Asegúrate de que tu perfil de aprovisionamiento incluya estos permisos si son necesarios.

## 🎯 Próximos pasos

1. **Para testing inicial**: Usa el workflow unsigned
2. **Para distribución**: Configura los certificados y usa el workflow firmado
3. **Para releases**: Crea tags en Git para generar releases automáticos

```bash
# Crear un tag para release
git tag v1.0.0
git push origin v1.0.0
```

El archivo .ipa generado estará disponible como artifact y en releases.