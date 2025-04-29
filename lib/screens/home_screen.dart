import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:xml/xml.dart' as xml;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';
import 'predict_screen.dart';
import 'profile_screen.dart';
import 'prediction_history_screen.dart';
import 'chart_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> monthlyMaxes = [];
  Map<String, dynamic>? overallMax;
  bool isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> importFile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [XTypeGroup(label: 'XML', extensions: ['xml'])],
      );
      if (file != null) {
        final filePath = file.path;
        final data = await compute(processXmlFile, filePath);

        setState(() {
          monthlyMaxes = List<Map<String, dynamic>>.from(data['monthlyMaxes']);
          overallMax = data['overallMax'];
        });

        await saveHeartRateData(data['monthlyMaxes'], data['overallMax']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xử lý file: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveHeartRateData(List<dynamic> monthlyMaxes, Map<String, dynamic> overallMax) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn chưa đăng nhập')),
      );
      return;
    }
    try {
      await _firestore.collection('heart_rate_data').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'overallMax': overallMax,
        'monthlyMaxes': monthlyMaxes,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu dữ liệu thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lưu dữ liệu: $e')),
      );
    }
  }

  static Future<Map<String, dynamic>> processXmlFile(dynamic filePath) async {
    final file = File(filePath);
    final xmlString = await file.readAsString();
    final document = xml.XmlDocument.parse(xmlString);

    final monthlyData = <String, List<Map<String, dynamic>>>{};

    for (final record in document.findAllElements('Record')) {
      final startDateStr = record.getAttribute('startDate');
      if (startDateStr != null) {
        final startDate = DateTime.parse(startDateStr);
        final monthKey = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}';
        final dateStr = startDate.toIso8601String().split('T')[0];

        for (final bpmElem in record.findAllElements('InstantaneousBeatsPerMinute')) {
          final time = bpmElem.getAttribute('time');
          final bpm = int.parse(bpmElem.getAttribute('bpm') ?? '0');
          monthlyData.putIfAbsent(monthKey, () => []).add({
            'date': dateStr,
            'time': time,
            'bpm': bpm,
          });
        }
      }
    }

    final monthlyMaxes = <Map<String, dynamic>>[];
    Map<String, dynamic>? overallMax;

    for (var month in monthlyData.keys) {
      var entries = monthlyData[month]!;
      if (entries.isNotEmpty) {
        var maxEntry = entries.fold(
          entries.first,
          (max, e) => e['bpm'] > max['bpm'] ? e : max,
        );
        monthlyMaxes.add({
          'month': month,
          'date': maxEntry['date'],
          'time': maxEntry['time'],
          'bpm': maxEntry['bpm'],
        });
        if (overallMax == null || maxEntry['bpm'] > overallMax['bpm']) {
          overallMax = maxEntry;
        }
      }
    }

    return {'monthlyMaxes': monthlyMaxes, 'overallMax': overallMax};
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final greeting = getGreeting(now);
    final icon = getWeatherIcon(now);
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    final List<Widget> screens = [
      _buildHomeScreen(now, greeting, icon, days),
      HeartChartsScreen(),
      ChatScreen(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Biểu đồ'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Trò chuyện'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(DateTime now, String greeting, Icon icon, List<DateTime> days) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Manh Dung,", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text(
                      greeting,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
                Row(
                  children: [
                    icon,
                    const SizedBox(width: 10),
                    const CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      radius: 16,
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "Bạn đã ngủ ", style: TextStyle(color: Colors.white, fontSize: 16)),
                    TextSpan(text: "10 tiếng, ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    TextSpan(text: "cao hơn mức khuyến nghị", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Lịch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) {
                final weekday = DateFormat.E('vi_VN').format(day);
                final dateStr = DateFormat.d().format(day);
                final isActive = day.day == now.day;
                return _dateItem(weekday, dateStr, isActive);
              }).toList(),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PredictFormScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.favorite, size: 32, color: Colors.deepPurple),
                          SizedBox(height: 8),
                          Text("Dự báo sức khỏe", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Xem nguy cơ tim mạch"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PredictionHistoryScreen()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.history, size: 32, color: Colors.deepPurple),
                          SizedBox(height: 8),
                          Text("Lịch sử dự đoán", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Xem lại các lần đã dự đoán"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Phân tích nhịp tim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: importFile,
              icon: const Icon(Icons.file_upload),
              label: const Text("Chọn file nhịp tim từ thiết bị"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
              ? const Center(child: CircularProgressIndicator())
              : monthlyMaxes.isEmpty
                ? const Text("Chưa có dữ liệu. Vui lòng tải file XML.", style: TextStyle(color: Colors.grey))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overallMax != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Nhịp tim cao nhất tổng thể:", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text("${overallMax!['bpm']} nhịp/phút - Ngày ${overallMax!['date']} lúc ${overallMax!['time']}", style: TextStyle()),
                              const Divider(height: 24, thickness: 1),
                            ],
                          ),
                        const Text("Nhịp tim cao nhất từng tháng:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ...monthlyMaxes.map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Tháng ${entry['month']} : ${entry['bpm']} nhịp/phút - ${entry['date']} lúc ${entry['time']}",
                              ),
                            )),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _dateItem(String day, String date, bool isActive) {
    return Column(
      children: [
        Text(day, style: TextStyle(color: isActive ? Colors.deepPurple : Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isActive ? Colors.deepPurple : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Text(
            date,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  String getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 10) return "Chào buổi sáng";
    if (hour < 16) return "Chào buổi chiều";
    return "Chào buổi tối";
  }

  Icon getWeatherIcon(DateTime now) {
    final hour = now.hour;
    if (hour >= 6 && hour < 16) {
      return const Icon(Icons.wb_sunny, color: Colors.orange);
    } else {
      return const Icon(Icons.nights_stay, color: Colors.indigo);
    }
  }
}
