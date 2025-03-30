import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart'; 
// import 'chart_screen.dart'; // placeholder nếu bạn có
// import 'profile_screen.dart'; // placeholder nếu bạn có

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final greeting = getGreeting(now);
    final icon = getWeatherIcon(now);
    final days = List.generate(6, (i) => now.add(Duration(days: i)));

    // Danh sách màn hình tương ứng bottom nav
    final List<Widget> screens = [
      _buildHomeScreen(now, greeting, icon, days),
      const Center(child: Text("Chart Screen")), // thay bằng ChartScreen()
      ChatScreen(), // dùng UI bạn đã xây dựng
      const Center(child: Text("Profile Screen")), // thay bằng ProfileScreen()
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Chart'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
            // Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Manh Dung,",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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

            // Sleep notification box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFB39DDB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "You have slept ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextSpan(
                      text: "09:30 ",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: "that is above your ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    TextSpan(
                      text: "recommendation",
                      style: TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Calendar
            const Text(
              "Calendar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: days.map((day) {
                final weekday = DateFormat.E().format(day);
                final dateStr = DateFormat.d().format(day);
                final isActive = day.day == now.day;
                return _dateItem(weekday, dateStr, isActive);
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Monthly changes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _changeCard("Monthly Change", "+26%", Colors.green),
                _changeCard("Monthly Change", "-30%", Colors.red),
              ],
            ),
            const SizedBox(height: 30),

            // Heart health card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Have a problem",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        Text(
                          "Heart?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: null,
                          child: Text("Consult"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/consult.png',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
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

  Widget _changeCard(String title, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(fontSize: 22, color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Icon(Icons.show_chart, color: color),
        ],
      ),
    );
  }

  String getGreeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  Icon getWeatherIcon(DateTime now) {
    final hour = now.hour;
    if (hour >= 6 && hour < 18) {
      return const Icon(Icons.wb_sunny, color: Colors.orange);
    } else {
      return const Icon(Icons.nights_stay, color: Colors.indigo);
    }
  }
}
