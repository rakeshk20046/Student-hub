import 'package:flutter/material.dart';

class StudentManagementScreen extends StatelessWidget {
  const StudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Student Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF140D2F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF140D2F), Color(0xFF2C1951)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: const Center(
          // This is a placeholder. You can replace this with your actual UI.
          child: Text(
            'Teacher\'s student management interface goes here.',
            style: TextStyle(fontSize: 20, color: Colors.white70),
          ),
        ),
      ),
    );
  }
}
