
class Medicao {
  final int numeroLeitura;
  final String ambiente;
  final String rede;
  final int rssi;

  Medicao({
    required this.numeroLeitura,
    required this.ambiente,
    required this.rede,
    required this.rssi,
  });

  factory Medicao.fromJson(Map<String, dynamic> json) {
    return Medicao(
      numeroLeitura: json['numero_leitura'],
      ambiente: json['ambiente'],
      rede: json['rede'],
      rssi: json['rssi'],
    );
  }
}
