import 'package:flutter/material.dart';
import 'personal_screen.dart';
import 'home_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color primaryColor = Color(0xFF673AB7); // Tím chuẩn DeepSeek

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          },
        ),
        title: const Text(
          'Thông tin',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.mail, color: primaryColor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thông tin cá nhân
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Mạnh Dũng",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text("01.01.1990"),
                        Text("+84 123456789"),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: primaryColor),
                ],
              ),
            ),

            // Lịch sử y tế
            buildInfoCard(
              icon: Icons.medical_services,
              title: "Lịch sử y tế",
              subtitle: "Xem các thông tin y tế đã lưu",
              buttonText: "Xem",
              color: primaryColor,
            ),

            // Lịch sử thưởng
            buildInfoCard(
              icon: Icons.history,
              title: "Lịch sử thưởng",
              subtitle: "Nhận điểm tích lũy và đổi quà",
              buttonText: "Xem",
              color: primaryColor,
            ),

            // Các mục đơn giản
            buildSimpleCard("Thông tin cá nhân", Icons.person, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),

            buildSimpleCard("Cập nhật sức khỏe", Icons.favorite, onTap: () {}),

            buildSimpleCard("Quên mật khẩu", Icons.lock_reset, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }),

            buildSimpleCard("Ngôn ngữ", Icons.language, onTap: () {}),

            buildSimpleCard("Thông báo", Icons.notifications, onTap: () {}),

            buildSimpleCard("Bảo mật", Icons.lock, onTap: () {}),

            buildSimpleCard("Hỗ trợ", Icons.support_agent, onTap: () {}),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white, // Chữ trắng đậm
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {},
            child: const Text("Xem", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget buildSimpleCard(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
