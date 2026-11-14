import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Excepción con un mensaje listo para mostrarse al usuario.
class ExchangeRateException implements Exception {
  final String userMessage;
  const ExchangeRateException(this.userMessage);

  @override
  String toString() => userMessage;
}

/// Servicio que consulta el tipo de cambio USD → MXN en una API pública.
///
/// Seguridad: la URL usa HTTPS (Android bloquea HTTP sin cifrar por defecto).
/// Robustez: cualquier falla se convierte en [ExchangeRateException] para que
/// la pantalla muestre un mensaje en lugar de cerrarse.
class ExchangeRateService {
  static final Uri _apiUrl = Uri.parse('https://open.er-api.com/v6/latest/USD');
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;

  ExchangeRateService({http.Client? client}) : _client = client ?? http.Client();

  /// Devuelve cuántos pesos mexicanos vale 1 dólar.
  Future<double> fetchUsdToMxn() async {
    try {
      final response = await _client.get(_apiUrl).timeout(_timeout);

      if (response.statusCode != 200) {
        throw ExchangeRateException(
            'El servidor respondió con error (${response.statusCode}).');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rates = data['rates'] as Map<String, dynamic>?;
      final mxn = rates?['MXN'];
      if (mxn is! num) {
        throw const ExchangeRateException('Respuesta inesperada del servidor.');
      }
      return mxn.toDouble();
    } on ExchangeRateException {
      rethrow;
    } on SocketException {
      throw const ExchangeRateException('Sin conexión a internet.');
    } on TimeoutException {
      throw const ExchangeRateException('La consulta tardó demasiado.');
    } catch (_) {
      throw const ExchangeRateException(
          'No se pudo obtener el tipo de cambio.');
    }
  }
}
