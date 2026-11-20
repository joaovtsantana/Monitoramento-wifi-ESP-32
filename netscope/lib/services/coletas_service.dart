
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/medicao.dart';
import '../models/coleta_detalhe.dart';

class ColetasService {
  final String apiUrl = 'http://localhost:3001/coletas';

  Future<List<Map<String, dynamic>>> listarColetas() async {
    final resposta = await http.get(Uri.parse(apiUrl));

    if (resposta.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(resposta.body),
      );
    }

    throw Exception('Erro ao buscar coletas');
  }

  Future<ColetaDetalhe> buscarDetalhes(int id) async {
    final resposta = await http.get(
      Uri.parse('$apiUrl/$id'),
    );

    if (resposta.statusCode == 200) {
      return ColetaDetalhe.fromJson(
        jsonDecode(resposta.body),
      );
    }

    throw Exception('Erro ao buscar detalhes da coleta');
  }
}
