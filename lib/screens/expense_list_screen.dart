import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../services/exchange_rate_service.dart';
import '../services/expense_provider.dart';
import 'add_expense_screen.dart';

/// Formato de moneda en pesos mexicanos.
final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'es_MX', symbol: r'$');

/// Pantalla principal: tipo de cambio, total y lista de gastos.
class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  /// Navega al formulario para agregar un gasto nuevo.
  void _openAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Gastos'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          const ExchangeRateBanner(),
          _TotalCard(total: provider.total, count: provider.expenses.length),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.expenses.isEmpty
                    ? const _EmptyState()
                    // Lista eficiente: sólo construye los elementos visibles.
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: provider.expenses.length,
                        itemBuilder: (context, index) => _ExpenseTile(
                          expense: provider.expenses[index],
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar gasto'),
      ),
    );
  }
}

/// Muestra el tipo de cambio del dólar consultado por HTTPS.
/// Si la consulta falla, muestra un mensaje y un botón para reintentar.
class ExchangeRateBanner extends StatefulWidget {
  const ExchangeRateBanner({super.key});

  @override
  State<ExchangeRateBanner> createState() => _ExchangeRateBannerState();
}

class _ExchangeRateBannerState extends State<ExchangeRateBanner> {
  double? _rate;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  /// Consulta el servicio y actualiza el estado con setState.
  Future<void> _loadRate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final service = context.read<ExchangeRateService>();
    try {
      final rate = await service.fetchUsdToMxn();
      if (!mounted) return;
      setState(() {
        _rate = rate;
        _isLoading = false;
      });
    } on ExchangeRateException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.userMessage;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget content;
    if (_isLoading) {
      content = const Row(
        children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Consultando tipo de cambio…'),
        ],
      );
    } else if (_errorMessage != null) {
      content = Row(
        children: [
          Icon(Icons.wifi_off, color: colors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text('$_errorMessage\nTipo de cambio no disponible.',
                style: TextStyle(color: colors.error)),
          ),
          TextButton(onPressed: _loadRate, child: const Text('Reintentar')),
        ],
      );
    } else {
      content = Row(
        children: [
          Icon(Icons.attach_money, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '1 USD = ${currencyFormat.format(_rate)} MXN',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loadRate,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: content,
      ),
    );
  }
}

/// Tarjeta con el total acumulado.
class _TotalCard extends StatelessWidget {
  final double total;
  final int count;

  const _TotalCard({required this.total, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primary,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total gastado',
                    style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(total),
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text('$count ${count == 1 ? 'gasto' : 'gastos'}',
                style: TextStyle(color: colors.onPrimary)),
          ],
        ),
      ),
    );
  }
}

/// Un renglón de la lista. Se elimina deslizando o con el botón de basura.
class _ExpenseTile extends StatelessWidget {
  final Expense expense;

  const _ExpenseTile({required this.expense});

  /// Pide confirmación antes de borrar.
  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text('¿Eliminar "${expense.concept}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<ExpenseProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await provider.deleteExpense(expense.id);
    messenger.showSnackBar(
      SnackBar(content: Text('"${expense.concept}" eliminado')),
    );
  }

  /// Muestra la foto del ticket en tamaño completo.
  void _showReceipt(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.file(
            File(expense.receiptImagePath!),
            errorBuilder: (context, error, stackTrace) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No se encontró la imagen.'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasReceipt = expense.receiptImagePath != null;
    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(expense.date);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: hasReceipt ? () => _showReceipt(context) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: hasReceipt
                  ? Image.file(
                      File(expense.receiptImagePath!),
                      fit: BoxFit.cover,
                      cacheWidth: 144, // Optimización: miniatura ligera
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    )
                  : Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.receipt_long),
                    ),
            ),
          ),
        ),
        title: Text(expense.concept),
        subtitle: Text(dateText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currencyFormat.format(expense.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await _confirmDelete(context) && context.mounted) {
                  await _delete(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje cuando todavía no hay gastos.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aún no tienes gastos registrados.',
                textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text('Toca "Agregar gasto" para empezar.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
