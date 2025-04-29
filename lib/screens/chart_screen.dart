import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_screen.dart';

class HeartChartsScreen extends StatefulWidget {
  const HeartChartsScreen({super.key});

  @override
  State<HeartChartsScreen> createState() => _HeartChartsScreenState();
}

class _HeartChartsScreenState extends State<HeartChartsScreen> {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ Nhịp Tim & Bệnh Tim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Bar chart
            const Text(
              'Nhịp tim cao nhất theo tháng',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('heart_rate_data')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final fetched = <Map<String, dynamic>>[];
                  for (var doc in snapshot.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final m = d['monthlyMaxes'] as List<dynamic>?;
                    if (m != null && m.isNotEmpty) {
                      final e = m.first;
                      if (e['bpm'] != null && e['month'] != null) {
                        fetched.add({'month': e['month'], 'bpm': e['bpm']});
                      }
                    }
                  }

                  final monthlyMaxes = fetched.reversed.take(5).toList();

                  if (monthlyMaxes.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu nhịp tim'));
                  }

                  return BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 120,
                      barGroups: List.generate(monthlyMaxes.length, (i) {
                        final bpm = (monthlyMaxes[i]['bpm'] as num).toDouble();
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: bpm,
                              width: 24,
                              color: Colors.blueAccent,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < monthlyMaxes.length) {
                                final raw = monthlyMaxes[idx]['month'] as String;
                                final dt = DateTime.parse('$raw-01');
                                return Text(
                                  '${dt.month.toString().padLeft(2, '0')}/${(dt.year % 100).toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Line chart
            const Text(
              'Tỷ lệ dự đoán mắc bệnh tim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('prediction_history')
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .limit(4)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu dự đoán'));
                  }

                  final records = docs.reversed.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final result = d['result'] as Map<String, dynamic>?;
                    final acc = result?['average_accuracy'];
                    final ts = d['timestamp'];
                    if (acc == null || ts == null) return null;

                    DateTime date;
                    if (ts is Timestamp) {
                      date = ts.toDate();
                    } else if (ts is String) {
                      date = DateTime.parse(ts);
                    } else {
                      return null;
                    }

                    return {
                      'accuracy': (acc as num).toDouble(),
                      'timestamp': date,
                    };
                  }).whereType<Map<String, dynamic>>().toList();

                  final count = records.length;

                  return LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: count - 1,
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      clipData: FlClipData.none(),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < count) {
                                final date = records[idx]['timestamp'] as DateTime;
                                return Text(
                                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${(date.year % 100).toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            interval: 20,
                            getTitlesWidget: (value, meta) {
                              if (value == 100) {
                                return const Align(
                                  alignment: Alignment.centerRight,
                                  child: Text('100%', style: TextStyle(fontSize: 10)),
                                );
                              }
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            count,
                            (i) => FlSpot(i.toDouble(), records[i]['accuracy'] as double),
                          ),
                          isCurved: true,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: false),
                          dotData: FlDotData(show: true),
                          color: Colors.pink,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
