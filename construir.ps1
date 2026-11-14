# Genera el APK de "Mis Gastos" y el .zip de entrega (Windows / PowerShell).
# Uso: abrir PowerShell en esta carpeta y ejecutar:  .\construir.ps1
# Si Windows bloquea el script:  powershell -ExecutionPolicy Bypass -File .\construir.ps1
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

Write-Host "1/6 Completando la carpeta android (no sobrescribe archivos existentes)..."
flutter create . --platforms=android --project-name mis_gastos --org com.misgastos
if ($LASTEXITCODE -ne 0) { throw "flutter create falló" }

Write-Host "2/6 Descargando dependencias..."
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "pub get falló" }

Write-Host "3/6 Generando ícono personalizado..."
dart run flutter_launcher_icons
if ($LASTEXITCODE -ne 0) { throw "flutter_launcher_icons falló" }

Write-Host "4/6 Revisando el código..."
flutter analyze
flutter test

Write-Host "5/6 Compilando APK de release..."
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw "build apk falló" }
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "MisGastos.apk" -Force

Write-Host "6/6 Creando MisGastos_entrega.zip (sin build/, .dart_tool/ ni carpetas de caché)..."
$staging = Join-Path $env:TEMP "mis_gastos_entrega"
if (Test-Path $staging) { Remove-Item $staging -Recurse -Force }
$excluir = @("build", ".dart_tool", ".gradle", ".idea", "node_modules")
robocopy . "$staging\mis_gastos" /E /XD $excluir /XF "MisGastos_entrega.zip" "MisGastos.apk" /NFL /NDL /NJH /NJS | Out-Null
Copy-Item "MisGastos.apk" "$staging\MisGastos.apk"
if (Test-Path "MisGastos_entrega.zip") { Remove-Item "MisGastos_entrega.zip" }
Compress-Archive -Path "$staging\*" -DestinationPath "MisGastos_entrega.zip"
Remove-Item $staging -Recurse -Force

Write-Host "Listo: MisGastos.apk y MisGastos_entrega.zip"
