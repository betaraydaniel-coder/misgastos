import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/expense_list_screen.dart';
import 'services/exchange_rate_service.dart';
import 'services/expense_provider.dart';
import 'services/expense_storage_service.dart';
import 'services/receipt_image_service.dart';

/// Punto de entrada de la aplicación "Mis Gastos".
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Se crean los servicios una sola vez y se comparten con Provider.
  final storageService = ExpenseStorageService();
  final imageService = ReceiptImageService();

  runApp(
    MultiProvider(
      providers: [
        Provider<ReceiptImageService>.value(value: imageService),
        Provider<ExchangeRateService>(create: (_) => ExchangeRateService()),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (_) =>
              ExpenseProvider(storageService, imageService)..loadExpenses(),
        ),
      ],
      child: const MisGastosApp(),
    ),
  );
}

class MisGastosApp extends StatelessWidget {
  const MisGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mis Gastos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: const ExpenseListScreen(),
    );
  }
}
