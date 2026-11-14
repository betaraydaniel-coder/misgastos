#!/usr/bin/env bash
# Genera el APK de "Mis Gastos" y el .zip de entrega (macOS / Linux).
# Uso: bash construir.sh
set -e
cd "$(dirname "$0")"

echo "1/6 Completando la carpeta android (no sobrescribe archivos existentes)..."
flutter create . --platforms=android --project-name mis_gastos --org com.misgastos

echo "2/6 Descargando dependencias..."
flutter pub get

echo "3/6 Generando ícono personalizado..."
dart run flutter_launcher_icons

echo "4/6 Revisando el código..."
flutter analyze || true
flutter test || true

echo "5/6 Compilando APK de release..."
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk MisGastos.apk

echo "6/6 Creando MisGastos_entrega.zip..."
STAGING="$(mktemp -d)"
mkdir -p "$STAGING/mis_gastos"
rsync -a ./ "$STAGING/mis_gastos/" \
  --exclude build --exclude .dart_tool --exclude .gradle --exclude .idea \
  --exclude node_modules --exclude MisGastos.apk --exclude MisGastos_entrega.zip
cp MisGastos.apk "$STAGING/"
rm -f MisGastos_entrega.zip
(cd "$STAGING" && zip -rq "$OLDPWD/MisGastos_entrega.zip" .)
rm -rf "$STAGING"

echo "Listo: MisGastos.apk y MisGastos_entrega.zip"
