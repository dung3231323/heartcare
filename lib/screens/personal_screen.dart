import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final genderController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final diseaseController = TextEditingController();

  int currentStep = 1;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      nameController.text = data['name'] ?? '';
      ageController.text = (data['age'] ?? '').toString();
      genderController.text = data['gender'] ?? '';
      phoneController.text = data['phone'] ?? '';
      emailController.text = data['email'] ?? '';
      addressController.text = data['address'] ?? '';
      diseaseController.text = data['disease'] ?? '';
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Thông tin cá nhân', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildProgressIndicator(),
                  const SizedBox(height: 20),
                  if (currentStep == 1) _buildForm(),
                  if (currentStep == 2) _buildSuccessScreen(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.circle, size: 12, color: currentStep >= 1 ? Colors.deepPurple : Colors.grey),
        const SizedBox(width: 8),
        Container(width: 30, height: 2, color: currentStep >= 2 ? Colors.deepPurple : Colors.grey),
        const SizedBox(width: 8),
        Icon(Icons.circle, size: 12, color: currentStep >= 2 ? Colors.deepPurple : Colors.grey),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(label: "Họ và tên", controller: nameController),
          _buildTextField(label: "Tuổi", controller: ageController, keyboardType: TextInputType.number),
          _buildTextField(label: "Giới tính", controller: genderController),
          _buildTextField(label: "Số điện thoại", controller: phoneController, keyboardType: TextInputType.phone),
          _buildTextField(label: "Gmail", controller: emailController, keyboardType: TextInputType.emailAddress),
          _buildTextField(label: "Địa chỉ nhà", controller: addressController),
          _buildTextField(label: "Bệnh nền", controller: diseaseController),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _handleSubmit,
              child: const Text('Xác nhận', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Icon(Icons.check_circle, size: 100, color: Colors.deepPurple),
          const SizedBox(height: 24),
          const Text(
            "Đã cập nhật thành công!",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        await FirebaseFirestore.instance.collection('user_profiles').doc(user.uid).set({
          'name': nameController.text.trim(),
          'age': int.tryParse(ageController.text.trim()) ?? 0,
          'gender': genderController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
          'address': addressController.text.trim(),
          'disease': diseaseController.text.trim(),
          'timestamp': DateTime.now(),
        });

        setState(() {
          currentStep = 2;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Vui lòng nhập $label';
          }
          return null;
        },
      ),
    );
  }
}
