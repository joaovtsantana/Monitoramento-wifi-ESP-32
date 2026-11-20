
import 'medicao.dart';

class ColetaDetalhe {
  final int id;
  final DateTime dataColeta;
  final String descricao;
  final List<Medicao> medicoes;

  ColetaDetalhe({
    required this.id,
    required this.dataColeta,
    required this.descricao,
    required this.medicoes,
  });

  factory ColetaDetalhe.fromJson(Map<String, dynamic> json) {
    final coleta = json['coleta'];

    return ColetaDetalhe(
      id: coleta['id'],
      dataColeta: DateTime.parse(coleta['data_coleta']),
      descricao: coleta['descricao'] ?? '',
      medicoes: (json['medicoes'] as List)
          .map((item) => Medicao.fromJson(item))
          .toList(),
    );
  }
}
