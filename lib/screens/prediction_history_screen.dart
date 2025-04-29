
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PredictionHistoryScreen extends StatelessWidget {
  const PredictionHistoryScreen({super.key});

  static const Map<String, String> fieldLabels = {
    "Heart disease": "Bệnh tim",
    "Age": "Tuổi",
    "Sex": "Giới tính",
    "ChestPainType": "Loại đau ngực",
    "RestingBP": "Huyết áp nghỉ",
    "Cholesterol": "Cholesterol",
    "FastingBS": "Đường huyết lúc đói (0/1)",
    "MaxHR": "Nhịp tim tối đa",
    "ExerciseAngina": "Đau ngực khi gắng sức (Y/N)",
    "Oldpeak": "Oldpeak (ST chênh xuống)",
    "ST_Slope": "ST Slope",
  };

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử dự đoán"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("prediction_history")
            .where("userId", isEqualTo: userId)
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print("UserID hiện tại: $userId");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu nào."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final timestamp = DateTime.tryParse(doc['timestamp'] ?? '');
              final formatted = timestamp != null
                  ? DateFormat('dd/MM/yyyy – HH:mm').format(timestamp)
                  : 'Không rõ thời gian';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text("Dự đoán lúc $formatted"),
                  subtitle: const Text("Nhấn để xem chi tiết"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    final inputs = doc['inputs'] as Map<String, dynamic>;
                    final result = doc['result'] as Map<String, dynamic>;
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      isScrollControlled: true,
                      builder: (_) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.6,
                        minChildSize: 0.4,
                        maxChildSize: 0.95,
                        builder: (context, scrollController) => Padding(
                          padding: const EdgeInsets.all(20),
                          child: ListView(
                            controller: scrollController,
                            children: [
                              const Text("🧠 Kết quả dự đoán",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Text("Tỉ lệ %: ${result['average_accuracy']}",
                                  style: const TextStyle(fontSize: 16)),
                              Text("Kết quả: ${result['prediction']}",
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 20),
                              const Text("📋 Thông tin đầu vào",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              ...inputs.entries.map((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            "${fieldLabels[e.key] ?? e.key}:",
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text("${e.value}"),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
