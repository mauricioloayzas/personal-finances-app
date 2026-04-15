# MIFINPER - Frontend

Aplicación Flutter para control de finanzas personales.

## Requisitos previos

- Flutter SDK instalado
- Android SDK (para builds Android)
- Archivos de entorno configurados: `.env.dev` y `.env.prod`

## Ejecutar en modo desarrollo

```bash
flutter run --target lib/main_dev.dart
```

## Ejecutar en modo producción

```bash
flutter run --target lib/main_prod.dart
```

## Tests

### Ejecutar todos los tests

```bash
flutter test
```

### Ejecutar tests con reporte detallado

```bash
flutter test --reporter expanded
```

### Ejecutar un archivo de test específico

```bash
flutter test test/<nombre_del_archivo>_test.dart
```

## Generar APK

### APK desarrollo (debug)

```bash
flutter build apk --target lib/main_dev.dart --debug
```

### APK desarrollo (release)

```bash
flutter build apk --target lib/main_dev.dart --release
```

### APK producción (release)

```bash
flutter build apk --target lib/main_prod.dart --release
```

### APK producción split por ABI (tamaño reducido)

```bash
flutter build apk --target lib/main_prod.dart --release --split-per-abi
```

Los APKs generados se encuentran en:
- `build/app/outputs/flutter-apk/`

## Generar App Bundle (AAB) para Play Store

### Bundle desarrollo

```bash
flutter build appbundle --target lib/main_dev.dart --release
```

### Bundle producción

```bash
flutter build appbundle --target lib/main_prod.dart --release
```

El AAB generado se encuentra en:
- `build/app/outputs/bundle/release/app-release.aab`

## Variables de entorno

El proyecto usa dos archivos de entorno:

- `.env.dev` — configuración para desarrollo
- `.env.prod` — configuración para producción

Variables requeridas:

```
API_ORCHESTRATOR_URL=
API_PF_URL=
SERVICE_PROFILE_ID=
APLICATION_ID=
ROLE_ID=
```

## Dependencias

```bash
flutter pub get
```

## Linting

```bash
flutter analyze
```
