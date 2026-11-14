import 'package:flutter_test/flutter_test.dart';
import 'package:mis_gastos/models/expense.dart';

void main() {
  test('Expense se convierte a JSON y de regreso sin perder datos', () {
    final original = Expense(
      id: '1',
      concept: 'Despensa',
      amount: 450.5,
      date: DateTime(2026, 10, 15, 11, 0),
      receiptImagePath: '/data/tickets/ticket_1.jpg',
    );

    final copy = Expense.fromJson(original.toJson());

    expect(copy.id, original.id);
    expect(copy.concept, original.concept);
    expect(copy.amount, original.amount);
    expect(copy.date, original.date);
    expect(copy.receiptImagePath, original.receiptImagePath);
  });
}
