import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcademicProgressScreen extends StatefulWidget {
  const AcademicProgressScreen({super.key});

  @override
  State<AcademicProgressScreen> createState() => _AcademicProgressScreenState();
}

class _AcademicProgressScreenState extends State<AcademicProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF140D2F),
      appBar: AppBar(
        title: const Text(
          'Academic Progress',
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
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('User data not found.', style: TextStyle(color: Colors.white70)));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final enrolledCourseIds = userData['enrolledCourses'] is List ? List<String>.from(userData['enrolledCourses']) : <String>[];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(enrolledCourseIds.length),
                  const SizedBox(height: 24),
                  const Text(
                    'Enrolled Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEnrolledCoursesList(enrolledCourseIds),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int enrolledCoursesCount) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Summary',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildSummaryTile('Enrolled Courses', Icons.school, '$enrolledCoursesCount'),
            _buildSummaryTile('Average Grade', Icons.insights, 'N/A'), // Placeholder
            _buildSummaryTile('Assignments Completed', Icons.check_circle, 'N/A'), // Placeholder
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String title, IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 24),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCoursesList(List<String> courseIds) {
    if (courseIds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Not enrolled in any courses.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: courseIds.map((courseId) {
        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('courses').doc(courseId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text('Course not found.', style: TextStyle(color: Colors.white70));
            }

            final courseData = snapshot.data!.data() as Map<String, dynamic>;
            return _buildCourseCard(courseData);
          },
        );
      }).toList(),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> courseData) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          courseData['name'] ?? 'Untitled Course',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Teacher: ${courseData['teacherName'] ?? 'N/A'}\nGrade: N/A', // Placeholder for grades
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: () {
          // Navigate to a detailed course view
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Course details screen not yet implemented.')),
          );
        },
      ),
    );
  }
}
