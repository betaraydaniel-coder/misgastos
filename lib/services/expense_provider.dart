import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import 'expense_storage_service.dart';
import 'receipt_image_service.dart';

/// Estado global de la app (patrón Provider / ChangeNotifier).
///
/// Mantiene la lista de gastos en memoria y delega la persistencia
/// a [ExpenseStorageService]. Las pantallas sólo llaman a estos métodos.
class ExpenseProvider extends ChangeNotifier {
  final ExpenseStorageService _storage;
  final ReceiptImageService _imageService;

  ExpenseProvider(this._storage, this._imageService);

  List<Expense> _expenses = [];
  bool _isLoading = true;

  /// Lista de gastos, del más reciente al más antiguo (sólo lectura).
  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get isLoading => _isLoading;

  /// Suma de todos los montos.
  double get total => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Carga los gastos guardados al iniciar la app.
  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    _expenses = await _storage.loadExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));
    _isLoading = false;
    notifyListeners();
  }

  /// Agrega un gasto nuevo y lo guarda.
  Future<void> addExpense({
    required String concept,
    required double amount,
    String? receiptImagePath,
  }) async {
    final now = DateTime.now();
    final expense = Expense(
      id: now.millisecondsSinceEpoch.toString(),
      concept: concept,
      amount: amount,
      date: now,
      receiptImagePath: receiptImagePath,
    );
    _expenses.insert(0, expense);
    notifyListeners();
    await _storage.saveExpenses(_expenses);
  }

  /// Elimina un gasto (y su foto) y guarda la lista actualizada.
  Future<void> deleteExpense(String id) async {
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final removed = _expenses.removeAt(index);
    notifyListeners();
    await _storage.saveExpenses(_expenses);
    await _imageService.deleteImage(removed.receiptImagePath);
  }
}
