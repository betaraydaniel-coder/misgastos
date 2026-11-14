import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resultado de intentar obtener una foto del ticket.
enum ReceiptPickStatus { success, cancelled, permissionDenied, error }

class ReceiptPickResult {
  final ReceiptPickStatus status;
  final String? imagePath;

  const ReceiptPickResult(this.status, [this.imagePath]);
}

/// Servicio que encapsula la función nativa del dispositivo:
/// solicita permisos, abre la cámara o la galería y guarda la foto
/// en la carpeta privada de la app para que no se pierda.
class ReceiptImageService {
  final ImagePicker _picker = ImagePicker();

  /// Toma una foto con la cámara. Pide el permiso CAMERA antes de abrirla.
  Future<ReceiptPickResult> takePhoto() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      return const ReceiptPickResult(ReceiptPickStatus.permissionDenied);
    }
    return _pick(ImageSource.camera);
  }

  /// Elige una foto de la galería. En Android 13+ se usa el selector de
  /// fotos del sistema, que no requiere permiso de almacenamiento.
  Future<ReceiptPickResult> pickFromGallery() => _pick(ImageSource.gallery);

  /// Lógica común: abre el selector y copia la imagen a almacenamiento
  /// permanente (la ruta original es temporal y Android puede borrarla).
  Future<ReceiptPickResult> _pick(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280, // Optimización: reduce el tamaño de la foto
        imageQuality: 75,
      );
      if (pickedFile == null) {
        return const ReceiptPickResult(ReceiptPickStatus.cancelled);
      }

      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'tickets'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName =
          'ticket_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final savedFile =
          await File(pickedFile.path).copy(p.join(receiptsDir.path, fileName));

      return ReceiptPickResult(ReceiptPickStatus.success, savedFile.path);
    } catch (_) {
      return const ReceiptPickResult(ReceiptPickStatus.error);
    }
  }

  /// Borra la foto de un gasto eliminado para no ocupar espacio.
  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Si no se puede borrar no es crítico; se ignora.
    }
  }
}
