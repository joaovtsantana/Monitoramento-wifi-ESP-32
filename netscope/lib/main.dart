
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'models/coleta_detalhe.dart';
import 'models/medicao.dart';
import 'services/coletas_service.dart';

const fundo = Color(0xFF0B1120);
const painel = Color(0xFF111C30);
const card = Color(0xFF17243A);
const azul = Color(0xFF38BDF8);
const verde = Color(0xFF34D399);

void main() {
  runApp(const NetScopeApp());
}

class NetScopeApp extends StatelessWidget {
  const NetScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NetScope',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: fundo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azul,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const NetScopeHome(),
    );
  }
}

class NetScopeHome extends StatefulWidget {
  const NetScopeHome({super.key});

  @override
  State<NetScopeHome> createState() => _NetScopeHomeState();
}

class _NetScopeHomeState extends State<NetScopeHome> {
  final ColetasService service = ColetasService();

  late Future<List<Map<String, dynamic>>> coletasFuture;

  final Map<int, Future<ColetaDetalhe>> detalhesCache = {};

  int pagina = 0;
  int? coletaSelecionada;

  @override
  void initState() {
    super.initState();
    coletasFuture = service.listarColetas();
  }

  Future<ColetaDetalhe> buscarDetalhes(int id) {
    return detalhesCache.putIfAbsent(
      id,
      () => service.buscarDetalhes(id),
    );
  }

  void atualizar() {
    setState(() {
      coletasFuture = service.listarColetas();
      detalhesCache.clear();
    });
  }

  void abrirColeta(int id) {
    setState(() {
      coletaSelecionada = id;
      pagina = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 850;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (!mobile)
                  Sidebar(
                    pagina: pagina == 2 ? 1 : pagina,
                    onSelecionar: (valor) {
                      setState(() {
                        pagina = valor;
                        coletaSelecionada = null;
                      });
                    },
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Header(
                        onAtualizar: atualizar,
                        mobile: mobile,
                      ),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: coletasFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: azul,
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return ErroCarregamento(
                                erro: snapshot.error.toString(),
                                onTentar: atualizar,
                              );
                            }

                            final coletas = snapshot.data ?? [];

                            if (pagina == 1) {
                              return ColetasPage(
                                coletas: coletas,
                                onAbrir: abrirColeta,
                              );
                            }

                            if (pagina == 2 && coletaSelecionada != null) {
                              return FutureBuilder<ColetaDetalhe>(
                                future: buscarDetalhes(coletaSelecionada!),
                                builder: (context, detalheSnapshot) {
                                  if (detalheSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: azul,
                                      ),
                                    );
                                  }

                                  if (detalheSnapshot.hasError) {
                                    return ErroCarregamento(
                                      erro: detalheSnapshot.error.toString(),
                                      onTentar: atualizar,
                                    );
                                  }

                                  return DetalhePage(
                                    detalhe: detalheSnapshot.data!,
                                    onVoltar: () {
                                      setState(() {
                                        pagina = 1;
                                        coletaSelecionada = null;
                                      });
                                    },
                                  );
                                },
                              );
                            }

                            return DashboardPage(
                              coletas: coletas,
                              buscarDetalhes: buscarDetalhes,
                              onAbrir: abrirColeta,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: mobile
              ? NavigationBar(
                  backgroundColor: painel,
                  selectedIndex: pagina == 2 ? 1 : pagina,
                  onDestinationSelected: (valor) {
                    setState(() {
                      pagina = valor;
                      coletaSelecionada = null;
                    });
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.wifi_find),
                      label: 'Coletas',
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}

// SIDEBAR

class Sidebar extends StatelessWidget {
  final int pagina;
  final Function(int) onSelecionar;

  const Sidebar({
    super.key,
    required this.pagina,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 245,
      color: painel,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 26,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.wifi, color: azul, size: 32),
              SizedBox(width: 10),
              Text(
                'NetScope',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'WI-FI MONITORING SYSTEM',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 50),
          const Text(
            'MENU PRINCIPAL',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          _item(
            Icons.dashboard_outlined,
            'Dashboard',
            0,
          ),
          _item(
            Icons.wifi_find,
            'Coletas',
            1,
          ),
          const Spacer(),
          const Divider(color: Colors.white12),
          const Row(
            children: [
              Icon(Icons.sensors, color: verde, size: 18),
              SizedBox(width: 9),
              Text(
                'Sistema conectado',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'NetScope • 2026',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String titulo, int valor) {
    final selecionado = pagina == valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelecionar(valor),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: selecionado
                ? azul.withValues(alpha: 0.13)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selecionado ? azul : Colors.white60,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: selecionado ? azul : Colors.white70,
                  fontWeight:
                      selecionado ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CABEÇALHO

class Header extends StatelessWidget {
  final VoidCallback onAtualizar;
  final bool mobile;

  const Header({
    super.key,
    required this.onAtualizar,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 30),
      decoration: const BoxDecoration(
        color: painel,
        border: Border(
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Monitoramento Wi-Fi',
              style: TextStyle(
                fontSize: mobile ? 17 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: onAtualizar,
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          if (!mobile)
            const CircleAvatar(
              backgroundColor: Color(0xFF263B56),
              child: Icon(Icons.person_outline, color: azul),
            ),
        ],
      ),
    );
  }
}

// DASHBOARD


class DashboardPage extends StatefulWidget {
  final List<Map<String, dynamic>> coletas;
  final Future<ColetaDetalhe> Function(int) buscarDetalhes;
  final Function(int) onAbrir;

  const DashboardPage({
    super.key,
    required this.coletas,
    required this.buscarDetalhes,
    required this.onAbrir,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? coletaSelecionada;

  @override
  void initState() {
    super.initState();

    if (widget.coletas.isNotEmpty) {
      coletaSelecionada = widget.coletas.first['id'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final coletas = widget.coletas;

    if (coletas.isEmpty) {
      return const Center(child: Text('Nenhuma coleta encontrada.'));
    }

    final coletaAtual = coletas.firstWhere(
      (c) => c['id'] == coletaSelecionada,
      orElse: () => coletas.first,
    );

    final id = coletaAtual['id'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visão geral',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Analise a cobertura e a intensidade das redes Wi-Fi.',
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 25),

          // SELETOR DE COLETA
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: painel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analisar coleta',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: id,
                  isExpanded: true,
                  dropdownColor: card,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.wifi,
                      color: azul,
                    ),
                    filled: true,
                    fillColor: card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: coletas.map((coleta) {
                    return DropdownMenuItem<int>(
                      value: coleta['id'] as int,
                      child: Text(
                        'Coleta #${coleta['id']} - ${coleta['descricao']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    if (valor != null) {
                      setState(() {
                        coletaSelecionada = valor;
                      });
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // DADOS DA COLETA SELECIONADA
          FutureBuilder<ColetaDetalhe>(
            future: widget.buscarDetalhes(id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: azul),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Erro ao carregar os detalhes desta coleta.',
                  style: TextStyle(color: Colors.redAccent),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final detalhe = snapshot.data!;
              final medicoes = detalhe.medicoes;

              final ambientes = medicoes
                  .map((m) => m.ambiente)
                  .toSet()
                  .length;

              final media = medicoes.isEmpty
                  ? 0.0
                  : medicoes.map((m) => m.rssi).reduce((a, b) => a + b) /
                      medicoes.length;

              final melhor = medicoes.isEmpty
                  ? null
                  : medicoes.map((m) => m.rssi).reduce((a, b) => a > b ? a : b);

              final pior = medicoes.isEmpty
                  ? null
                  : medicoes.map((m) => m.rssi).reduce((a, b) => a < b ? a : b);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Indicadores da coleta #${detalhe.id}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final colunas = constraints.maxWidth > 1050
                          ? 3
                          : constraints.maxWidth > 580
                              ? 2
                              : 1;

                      return GridView.count(
                        crossAxisCount: colunas,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: colunas == 1 ? 3.1 : 2.0,
                        children: [
                          IndicadorCard(
                            titulo: 'Total de coletas',
                            valor: '${coletas.length}',
                            icone: Icons.folder_open,
                            cor: azul,
                          ),
                          IndicadorCard(
                            titulo: 'Total de medições',
                            valor: '${medicoes.length}',
                            icone: Icons.analytics_outlined,
                            cor: verde,
                          ),
                          IndicadorCard(
                            titulo: 'Ambientes monitorados',
                            valor: '$ambientes',
                            icone: Icons.home_work_outlined,
                            cor: const Color(0xFFA78BFA),
                          ),
                          IndicadorCard(
                            titulo: 'RSSI médio',
                            valor: medicoes.isEmpty
                                ? '--'
                                : '${media.toStringAsFixed(1)} dBm',
                            icone: Icons.signal_wifi_4_bar,
                            cor: const Color(0xFFFBBF24),
                          ),
                          IndicadorCard(
                            titulo: 'Melhor sinal',
                            valor: melhor == null ? '--' : '$melhor dBm',
                            icone: Icons.signal_wifi_4_bar,
                            cor: verde,
                          ),
                          IndicadorCard(
                            titulo: 'Sinal mais fraco',
                            valor: pior == null ? '--' : '$pior dBm',
                            icone: Icons.signal_wifi_0_bar,
                            cor: Colors.redAccent,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  if (medicoes.isNotEmpty)
                    GraficoAmbientes(medicoes: medicoes)
                  else
                    const Text('Esta coleta não possui medições.'),

                  const SizedBox(height: 28),

                  const Text(
                    'Informações da coleta',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Descrição: ${detalhe.descricao}'),
                        const SizedBox(height: 8),
                        Text(
                          'Data: ${detalhe.dataColeta.toLocal().toString().substring(0, 16)}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        const SizedBox(height: 15),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () => widget.onAbrir(id),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Ver todas as medições'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 30),
          const SizedBox(height: 30),
          ComparacaoColetas(
            coletas: widget.coletas,
            buscarDetalhes: widget.buscarDetalhes,
          ),

          const SizedBox(height: 30),
          const Text(
            'Coletas recentes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...coletas.take(5).map((coleta) {
            final data = DateTime.parse(
              coleta['data_coleta'],
            ).toLocal();

            return CardColeta(
              id: coleta['id'],
              descricao: coleta['descricao'] ?? '',
              data: data,
              onTap: () => widget.onAbrir(coleta['id']),
            );
          }),
        ],
      ),
    );
  }
}


// CARD DE INDICADOR

class IndicadorCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const IndicadorCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ),
              Icon(icone, color: cor, size: 23),
            ],
          ),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// GRÁFICO DE RSSI

class GraficoAmbientes extends StatelessWidget {
  final List<Medicao> medicoes;

  const GraficoAmbientes({
    super.key,
    required this.medicoes,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<int>> grupos = {};

    for (final medicao in medicoes) {
      grupos.putIfAbsent(medicao.ambiente, () => []);
      grupos[medicao.ambiente]!.add(medicao.rssi);
    }

    final ambientes = grupos.keys.toList();

    final medias = ambientes.map((ambiente) {
      final valores = grupos[ambiente]!;
      return valores.reduce((a, b) => a + b) / valores.length;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intensidade do sinal por ambiente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Média de RSSI da coleta mais recente (dBm)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                minY: -100,
                maxY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white12,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} dBm',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 43,
                      interval: 25,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= ambientes.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            ambientes[index],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(ambientes.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        fromY: -100,
                        toY: medias[index],
                        width: 28,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        color: azul,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quanto mais próximo de 0 dBm, mais forte é o sinal.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// LISTA DE COLETAS

class ColetasPage extends StatelessWidget {
  final List<Map<String, dynamic>> coletas;
  final Function(int) onAbrir;

  const ColetasPage({
    super.key,
    required this.coletas,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(26),
      children: [
        const Text(
          'Histórico de coletas',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${coletas.length} coletas registradas no banco de dados',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 25),
        ...coletas.map((coleta) {
          final data = DateTime.parse(
            coleta['data_coleta'],
          ).toLocal();

          return CardColeta(
            id: coleta['id'],
            descricao: coleta['descricao'] ?? '',
            data: data,
            onTap: () => onAbrir(coleta['id']),
          );
        }),
      ],
    );
  }
}

class CardColeta extends StatelessWidget {
  final int id;
  final String descricao;
  final DateTime data;
  final VoidCallback onTap;

  const CardColeta({
    super.key,
    required this.id,
    required this.descricao,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';

    final horaFormatada =
        '${data.hour.toString().padLeft(2, '0')}:'
        '${data.minute.toString().padLeft(2, '0')}';

    return Card(
      color: card,
      margin: const EdgeInsets.only(bottom: 11),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: Colors.white10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 9,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF263B56),
          child: Icon(Icons.wifi, color: azul),
        ),
        title: Text(
          'Coleta #$id',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$descricao • $dataFormatada às $horaFormatada'),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white54,
        ),
        onTap: onTap,
      ),
    );
  }
}

// DETALHES DA COLETA

class DetalhePage extends StatelessWidget {
  final ColetaDetalhe detalhe;
  final VoidCallback onVoltar;

  const DetalhePage({
    super.key,
    required this.detalhe,
    required this.onVoltar,
  });

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<Medicao>>{};

    for (final medicao in detalhe.medicoes) {
      grupos.putIfAbsent(medicao.ambiente, () => []);
      grupos[medicao.ambiente]!.add(medicao);
    }

    return ListView(
      padding: const EdgeInsets.all(26),
      children: [
        TextButton.icon(
          onPressed: onVoltar,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Voltar para coletas'),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Coleta #${detalhe.id}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detalhe.descricao,
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 25),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _resumo(
              'Total de medições',
              '${detalhe.medicoes.length}',
            ),
            _resumo(
              'Ambientes',
              '${grupos.length}',
            ),
            _resumo(
              'Rede monitorada',
              detalhe.medicoes.isEmpty
                  ? '--'
                  : detalhe.medicoes.first.rede,
            ),
          ],
        ),

        const SizedBox(height: 28),
        const Text(
          'Medições por ambiente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        ...grupos.entries.map((entrada) {
          final valores = entrada.value;
          final media = valores
                  .map((m) => m.rssi)
                  .reduce((a, b) => a + b) /
              valores.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entrada.key,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${media.toStringAsFixed(1)} dBm',
                      style: const TextStyle(
                        color: azul,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${valores.length} medições registradas',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const Divider(color: Colors.white12, height: 25),
                ...valores.map((m) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Leitura ${m.numeroLeitura}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          '${m.rssi} dBm',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _resumo(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(17),
      constraints: const BoxConstraints(minWidth: 145),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ERROS

class ErroCarregamento extends StatelessWidget {
  final String erro;
  final VoidCallback onTentar;

  const ErroCarregamento({
    super.key,
    required this.erro,
    required this.onTentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.redAccent,
              size: 45,
            ),
            const SizedBox(height: 15),
            const Text(
              'Não foi possível carregar os dados',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              erro,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onTentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class ComparacaoColetas extends StatefulWidget {
  final List<Map<String, dynamic>> coletas;
  final Future<ColetaDetalhe> Function(int) buscarDetalhes;

  const ComparacaoColetas({
    super.key,
    required this.coletas,
    required this.buscarDetalhes,
  });

  @override
  State<ComparacaoColetas> createState() => _ComparacaoColetasState();
}

class _ComparacaoColetasState extends State<ComparacaoColetas> {
  late int coletaA;
  late int coletaB;

  @override
  void initState() {
    super.initState();

    coletaA = widget.coletas[0]['id'];
    coletaB = widget.coletas[1]['id'];
  }

  Map<String, double> calcularMedias(ColetaDetalhe detalhe) {
    final Map<String, List<int>> grupos = {};

    for (final medicao in detalhe.medicoes) {
      grupos.putIfAbsent(medicao.ambiente, () => []);
      grupos[medicao.ambiente]!.add(medicao.rssi);
    }

    return grupos.map((ambiente, valores) {
      final media = valores.reduce((a, b) => a + b) / valores.length;
      return MapEntry(ambiente, media);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.coletas.length < 2) {
      return const SizedBox.shrink();
    }

    final opcoesB = widget.coletas
        .where((c) => c['id'] != coletaA)
        .toList();

    final opcoesA = widget.coletas
        .where((c) => c['id'] != coletaB)
        .toList();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparação entre coletas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Compare a intensidade média do sinal entre duas medições.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (context, constraints) {
              final vertical = constraints.maxWidth < 550;

              final campoA = DropdownButtonFormField<int>(
                value: coletaA,
                isExpanded: true,
                dropdownColor: painel,
                decoration: const InputDecoration(
                  labelText: 'Primeira coleta',
                  prefixIcon: Icon(Icons.circle, color: azul),
                  border: OutlineInputBorder(),
                ),
                items: opcoesA.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text('Coleta #${c['id']}'),
                  );
                }).toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => coletaA = valor);
                  }
                },
              );

              final campoB = DropdownButtonFormField<int>(
                value: coletaB,
                isExpanded: true,
                dropdownColor: painel,
                decoration: const InputDecoration(
                  labelText: 'Segunda coleta',
                  prefixIcon: Icon(Icons.circle, color: verde),
                  border: OutlineInputBorder(),
                ),
                items: opcoesB.map((c) {
                  return DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text('Coleta #${c['id']}'),
                  );
                }).toList(),
                onChanged: (valor) {
                  if (valor != null) {
                    setState(() => coletaB = valor);
                  }
                },
              );

              if (vertical) {
                return Column(
                  children: [
                    campoA,
                    const SizedBox(height: 12),
                    campoB,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: campoA),
                  const SizedBox(width: 15),
                  Expanded(child: campoB),
                ],
              );
            },
          ),

          const SizedBox(height: 25),

          FutureBuilder<List<ColetaDetalhe>>(
            future: Future.wait([
              widget.buscarDetalhes(coletaA),
              widget.buscarDetalhes(coletaB),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(
                    child: CircularProgressIndicator(color: azul),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Text(
                  'Erro ao carregar as coletas para comparação.',
                  style: TextStyle(color: Colors.redAccent),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final mediasA = calcularMedias(snapshot.data![0]);
              final mediasB = calcularMedias(snapshot.data![1]);

              final ambientes = {
                ...mediasA.keys,
                ...mediasB.keys,
              }.toList()..sort();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _legenda('Coleta #$coletaA', azul),
                      const SizedBox(width: 20),
                      _legenda('Coleta #$coletaB', verde),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 280,
                    child: BarChart(
                      BarChartData(
                        minY: -100,
                        maxY: 0,
                        barGroups: List.generate(
                          ambientes.length,
                          (index) {
                            final ambiente = ambientes[index];

                            return BarChartGroupData(
                              x: index,
                              barsSpace: 6,
                              barRods: [
                                if (mediasA.containsKey(ambiente))
                                  BarChartRodData(
                                    fromY: -100,
                                    toY: mediasA[ambiente]!,
                                    color: azul,
                                    width: 15,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                if (mediasB.containsKey(ambiente))
                                  BarChartRodData(
                                    fromY: -100,
                                    toY: mediasB[ambiente]!,
                                    color: verde,
                                    width: 15,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white12,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              interval: 25,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();

                                if (index < 0 || index >= ambientes.length) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(
                                    ambientes[index],
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.toStringAsFixed(1)} dBm',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Variação do sinal por ambiente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ...ambientes.map((ambiente) {
                    final a = mediasA[ambiente];
                    final b = mediasB[ambiente];

                    if (a == null || b == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '$ambiente: ambiente ausente em uma das coletas',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final diferenca = b - a;
                    final melhorou = diferenca > 0;
                    final igual = diferenca == 0;

                    final texto = igual
                        ? 'Sem alteração'
                        : melhorou
                            ? 'Melhorou ${diferenca.abs().toStringAsFixed(1)} dB'
                            : 'Piorou ${diferenca.abs().toStringAsFixed(1)} dB';

                    final cor = igual
                        ? Colors.white54
                        : melhorou
                            ? verde
                            : Colors.redAccent;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 9),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: painel,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ambiente,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            texto,
                            style: TextStyle(
                              color: cor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legenda(String texto, Color cor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

