import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';

/// Servicio responsable de guardar y leer los gastos de forma persistente.
///
/// Las pantallas nunca acceden a SharedPreferences directamente: siempre
/// pasan por esta clase (a través del provider).
class ExpenseStorageService {
  /// Clave bajo la que se guarda la lista de gastos en formato JSON.
  static const String _storageKey = 'mis_gastos_expenses';

  /// Lee todos los gastos guardados. Si no hay datos o están dañados,
  /// devuelve una lista vacía en lugar de lanzar un error.
  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = prefs.getString(_storageKey);
    if (rawJson == null || rawJson.isEmpty) return [];

    try {
      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded
          .map((item) => Expense.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Datos corruptos: se ignoran para que la app no se cierre.
      return [];
    }
  }

  /// Guarda la lista completa de gastos.
  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final rawJson = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, rawJson);
  }
}
