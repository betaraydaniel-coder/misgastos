# Mis Gastos

Registro personal de gastos en Flutter: concepto, monto y foto del ticket; lista con total; eliminación; tipo de cambio USD→MXN en la pantalla principal.

## Cómo generar el APK y el .zip

Requisitos: Flutter 3.27 o superior y Android SDK (Android Studio). Verifica con `flutter doctor`.

- **Windows:** `powershell -ExecutionPolicy Bypass -File .\construir.ps1`
- **macOS / Linux:** `bash construir.sh`

El script completa la carpeta `android/`, descarga dependencias, genera el ícono, analiza el código, compila `MisGastos.apk` y crea `MisGastos_entrega.zip` (proyecto sin `build/` ni `.dart_tool/` + APK).

Para probar en emulador o teléfono: `flutter run`.

## Estructura

```
lib/
  main.dart                         Arranque, Provider y tema
  models/expense.dart               Modelo Gasto (+ JSON)
  services/expense_storage_service.dart   Persistencia (shared_preferences)
  services/expense_provider.dart          Estado (ChangeNotifier)
  services/receipt_image_service.dart     Cámara/galería + permiso
  services/exchange_rate_service.dart     API HTTPS tipo de cambio
  screens/expense_list_screen.dart  Lista, total, tipo de cambio
  screens/add_expense_screen.dart   Formulario de nuevo gasto
```

## Cumplimiento por tema

| Tema | Dónde |
|---|---|
| 1 Multiplataforma | Proyecto Flutter configurado para Android |
| 2–3 Pantallas, navegación, estado, lista | `Navigator.push`, Provider + `setState`, `ListView.builder`, `shared_preferences` |
| 4 Función nativa | `image_picker` (cámara/galería) + `permission_handler` (permiso CAMERA) |
| 5 Arquitectura | `models/`, `services/`, `screens/`; las pantallas no tocan el almacenamiento |
| 6 Seguridad | API `https://open.er-api.com`, timeout, `usesCleartextTraffic=false`, mensaje + "Reintentar" si falla |
| 7 Publicación | Nombre "Mis Gastos" en el manifiesto, ícono en `assets/icon/`, ficha de publicación |
