

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PredictFormScreen extends StatefulWidget {
  const PredictFormScreen({super.key});

  @override
  State<PredictFormScreen> createState() => _PredictFormScreenState();
}

class _PredictFormScreenState extends State<PredictFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Controllers
  final ageCtrl = TextEditingController();
  final restingBPCtrl = TextEditingController();
  final cholesterolCtrl = TextEditingController();
  final maxHRCtrl = TextEditingController();
  final oldpeakCtrl = TextEditingController();

  // Dropdown values
  String sex = 'M';
  String chestPainType = 'ATA';
  String fastingBS = '0';
  String exerciseAngina = 'N';
  String stSlope = 'Up';

  String? result;

  Future<void> predict() async {
  final uri = Uri.parse("http://ec2-13-211-132-6.ap-southeast-2.compute.amazonaws.com:8000/predict");

  final inputPayload = {
    "Age": int.tryParse(ageCtrl.text) ?? 0,
    "Sex": sex,
    "ChestPainType": chestPainType,
    "RestingBP": int.tryParse(restingBPCtrl.text) ?? 0,
    "Cholesterol": int.tryParse(cholesterolCtrl.text) ?? 0,
    "FastingBS": int.tryParse(fastingBS) ?? 0,
    "MaxHR": int.tryParse(maxHRCtrl.text) ?? 0,
    "ExerciseAngina": exerciseAngina,
    "Oldpeak": double.tryParse(oldpeakCtrl.text) ?? 0.0,
    "ST_Slope": stSlope
  };

  try {
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(inputPayload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prediction = data['prediction'];
      final interpretation = data['interpretation'];
      final votingModels = data['voting_models'];

      // Tính trung bình độ chính xác
      double averageAccuracy = 0.0;
      if (votingModels != null && votingModels is List) {
        double totalAccuracy = 0.0;
        for (var model in votingModels) {
          totalAccuracy += (model['accuracy'] ?? 0.0);
        }
        averageAccuracy = totalAccuracy / votingModels.length;
      }

      final conclusion = prediction == 1 ? "Mắc bệnh" : "Không mắc bệnh";

      String warning = '';

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection("prediction_history").add({
          "userId": userId,
          "inputs": inputPayload,
          "result": {
            "prediction": prediction,
            "average_accuracy": averageAccuracy,
            "conclusion": conclusion,
          },
          "timestamp": DateTime.now().toIso8601String(),
        });
      }

      setState(() {
        result = "🧠 KẾT QUẢ DỰ ĐOÁN\n\n"
                 "📊 Trung bình độ chính xác: ${averageAccuracy.toStringAsFixed(2)}%\n\n"
                 "🔎 Kết luận: $conclusion"
                 "$warning";
      });

      _scrollToBottom();
    } else {
      setState(() => result = 'Lỗi ${response.statusCode}');
      _scrollToBottom();
    }
  } catch (e) {
    setState(() => result = 'Lỗi kết nối');
    _scrollToBottom();
  }
}


  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dự đoán nguy cơ tim mạch"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextInput("Tuổi", ageCtrl, TextInputType.number),
              _buildDropdown("Giới tính (M/F)", sex, ["M", "F"], (val) => setState(() => sex = val!)),
              _buildDropdown("Loại đau ngực", chestPainType, ["ATA", "NAP", "ASY", "TA"], (val) => setState(() => chestPainType = val!)),
              _buildTextInput("Huyết áp nghỉ", restingBPCtrl, TextInputType.number),
              _buildTextInput("Cholesterol", cholesterolCtrl, TextInputType.number),
              _buildDropdown("FastingBS (0 hoặc 1)", fastingBS, ["0", "1"], (val) => setState(() => fastingBS = val!)),
              _buildTextInput("Nhịp tim tối đa", maxHRCtrl, TextInputType.number),
              _buildDropdown("Đau ngực khi gắng sức (Y/N)", exerciseAngina, ["Y", "N"], (val) => setState(() => exerciseAngina = val!)),
              _buildTextInput("Oldpeak (ST chênh xuống)", oldpeakCtrl, TextInputType.numberWithOptions(decimal: true), isDecimal: true),
              _buildDropdown("ST_Slope", stSlope, ["Up", "Flat", "Down"], (val) => setState(() => stSlope = val!)),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      predict();
                    }
                  },
                  child: const Text("Dự đoán", style: TextStyle(fontSize: 16)),
                ),
              ),
              if (result != null) ...[
                const SizedBox(height: 24),
                Text(
                  result!,
                  style: const TextStyle(fontSize: 15),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput(
    String label,
    TextEditingController controller,
    TextInputType type, {
    bool isDecimal = false,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Trường này là bắt buộc';
          }

          final number = isDecimal
              ? double.tryParse(value ?? '')
              : int.tryParse(value ?? '');

          if (number == null) return 'Vui lòng nhập số hợp lệ';
          if (number < 0) return 'Không được nhỏ hơn 0';
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

