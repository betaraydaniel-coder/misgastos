import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/expense_provider.dart';
import '../services/receipt_image_service.dart';

/// Formulario para registrar un gasto nuevo con foto opcional del ticket.
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  final _amountController = TextEditingController();

  String? _receiptImagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _conceptController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Valida que el monto sea un número mayor a cero.
  String? _validateAmount(String? value) {
    final amount = double.tryParse((value ?? '').replaceAll(',', '.'));
    if (amount == null) return 'Escribe un monto válido';
    if (amount <= 0) return 'El monto debe ser mayor a 0';
    return null;
  }

  /// Muestra opciones de cámara/galería y obtiene la foto mediante el servicio.
  Future<void> _attachReceipt() async {
    final imageService = context.read<ReceiptImageService>();

    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final result = source == 'camera'
        ? await imageService.takePhoto()
        : await imageService.pickFromGallery();
    if (!mounted) return;

    switch (result.status) {
      case ReceiptPickStatus.success:
        setState(() => _receiptImagePath = result.imagePath);
      case ReceiptPickStatus.cancelled:
        break;
      case ReceiptPickStatus.permissionDenied:
        _showMessage(
            'Se necesita permiso de cámara para tomar la foto del ticket.');
      case ReceiptPickStatus.error:
        _showMessage('No se pudo obtener la imagen. Intenta de nuevo.');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Valida el formulario, guarda a través del provider y regresa a la lista.
  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    await context.read<ExpenseProvider>().addExpense(
          concept: _conceptController.text.trim(),
          amount: amount,
          receiptImagePath: _receiptImagePath,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo gasto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _conceptController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                hintText: 'Ej. Despensa, gasolina…',
                prefixIcon: Icon(Icons.edit_note),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Escribe el concepto'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto (MXN)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: _validateAmount,
            ),
            const SizedBox(height: 24),
            Text('Foto del ticket (opcional)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ReceiptPreview(
              imagePath: _receiptImagePath,
              onTap: _attachReceipt,
              onRemove: () => setState(() => _receiptImagePath = null),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveExpense,
              icon: const Icon(Icons.save),
              label: const Text('Guardar gasto'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista previa de la foto o botón para adjuntarla.
class _ReceiptPreview extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ReceiptPreview({
    required this.imagePath,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (imagePath == null) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Adjuntar foto del ticket'),
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20)),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath!),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Cambiar foto',
                onPressed: onTap,
                icon: const Icon(Icons.edit),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Quitar foto',
                style: IconButton.styleFrom(backgroundColor: colors.error),
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
