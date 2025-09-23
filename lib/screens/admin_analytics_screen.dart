import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';
import '../models/order_status.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  final List<Order> orders;

  const AdminAnalyticsScreen({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Ventana de 14 días (hoy incluido)
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 13));
    final days = List<DateTime>.generate(14, (i) {
      final d = DateTime(start.year, start.month, start.day).add(Duration(days: i));
      return d;
    });

    // Buckets por día
    final Map<DateTime, double> salesByDay = { for (final d in days) d: 0.0 };
    double totalToday = 0;
    int ordersToday = 0;

    // Estados y productos
    final Map<OrderStatus, int> statusCounts = {};
    final Map<String, double> revenueByProduct = {};

    for (final o in orders) {
      final dayKey = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
      if (salesByDay.containsKey(dayKey)) {
        salesByDay[dayKey] = (salesByDay[dayKey] ?? 0) + o.total;
      }
      final isToday = dayKey == DateTime(now.year, now.month, now.day);
      if (isToday) {
        totalToday += o.total;
        ordersToday += 1;
      }
      statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
      for (final it in o.items) {
        revenueByProduct[it.productSnapshot.nombre] =
            (revenueByProduct[it.productSnapshot.nombre] ?? 0) + it.subtotal;
      }
    }

    final avgTicketToday = ordersToday == 0 ? 0.0 : totalToday / ordersToday;

    // Preparar datos para charts
    final dayEntries = salesByDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxY = dayEntries.fold<double>(0, (p, e) => e.value > p ? e.value : p);
    final safeMaxY = (maxY <= 0) ? 1.0 : maxY;

    final statusList = OrderStatus.values
        .map((s) => MapEntry(s, statusCounts[s] ?? 0))
        .where((e) => e.value > 0)
        .toList();

    final topProducts = (revenueByProduct.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Estadísticas")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPIs
          Row(
            children: [
              Expanded(child: _KpiCard(title: "Ingresos (hoy)", value: "\$${totalToday.toStringAsFixed(2)}")),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(title: "Pedidos (hoy)", value: "$ordersToday")),
              const SizedBox(width: 12),
              Expanded(child: _KpiCard(title: "Ticket prom.", value: "\$${avgTicketToday.toStringAsFixed(2)}")),
            ],
          ),
          const SizedBox(height: 20),

          // Ventas por día (BarChart)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ventas por día (14 días)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: BarChart(
                      BarChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          for (int i = 0; i < dayEntries.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: dayEntries[i].value,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                ),
                              ],
                            ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              getTitlesWidget: (value, meta) {
                                // Mostrar 4 ticks aprox
                                final step = safeMaxY / 4;
                                if (value % step < 0.01 || (step - (value % step)) < 0.01) {
                                  return Text("\$${value.toStringAsFixed(0)}",
                                      style: const TextStyle(fontSize: 10));
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= dayEntries.length) return const SizedBox.shrink();
                                final d = dayEntries[i].key;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text("${d.day}/${d.month}",
                                      style: const TextStyle(fontSize: 10)),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        maxY: safeMaxY * 1.1, // un margen
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estados (PieChart)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pedidos por estado", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (statusList.isEmpty)
                    const Text("Aún no hay datos suficientes.", style: TextStyle(color: Colors.grey))
                  else
                    SizedBox(
                      height: 220,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            for (final e in statusList)
                              PieChartSectionData(
                                value: e.value.toDouble(),
                                title: e.key.label,
                                radius: 70,
                                titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top productos (BarChart horizontal)
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Top productos por ingreso", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (topProducts.isEmpty)
                    const Text("Aún no hay datos suficientes.", style: TextStyle(color: Colors.grey))
                  else
                    SizedBox(
                      height: (topProducts.length * 40) + 40,
                      child: BarChart(
                        BarChartData(
                          gridData: FlGridData(show: true, drawVerticalLine: true),
                          borderData: FlBorderData(show: false),
                          alignment: BarChartAlignment.spaceBetween,
                          barGroups: [
                            for (int i = 0; i < topProducts.length; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: topProducts[i].value,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  final i = value.toInt();
                                  if (i < 0 || i >= topProducts.length) return const SizedBox.shrink();
                                  return Text("\$${topProducts[i].value.toStringAsFixed(0)}",
                                      style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Etiquetas a la izquierda (nombres)
                  if (topProducts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < topProducts.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text("• ${topProducts[i].key}",
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  const _KpiCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
