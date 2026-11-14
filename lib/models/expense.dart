/// Modelo que representa un gasto registrado por el usuario.
class Expense {
  /// Identificador único (se genera con la fecha en milisegundos).
  final String id;

  /// Descripción del gasto, por ejemplo "Despensa" o "Gasolina".
  final String concept;

  /// Monto del gasto en pesos.
  final double amount;

  /// Fecha en que se registró el gasto.
  final DateTime date;

  /// Ruta local de la foto del ticket (puede ser nula si no se adjuntó).
  final String? receiptImagePath;

  const Expense({
    required this.id,
    required this.concept,
    required this.amount,
    required this.date,
    this.receiptImagePath,
  });

  /// Convierte el gasto a un mapa para guardarlo como JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'concept': concept,
        'amount': amount,
        'date': date.toIso8601String(),
        'receiptImagePath': receiptImagePath,
      };

  /// Reconstruye un gasto a partir del JSON guardado.
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        concept: json['concept'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        receiptImagePath: json['receiptImagePath'] as String?,
      );
}
