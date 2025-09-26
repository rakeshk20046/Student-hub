import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Import the SettingsScreen

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    return PopScope(
      canPop: false, // Prevents navigating back.
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header with User's First Name
                _buildHeader(user.uid),
                const SizedBox(height: 24),
                // GPA/CGPA and Attendance Card
                _buildSummaryCard(user.uid),
                const SizedBox(height: 24),
                const Text(
                  'Upcoming Deadlines',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 16),
                // Upcoming Assignments List
                _buildUpcomingAssignments(user.uid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            'Welcome Back',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final firstName = userData?['firstName'] ?? 'User';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $firstName 👋',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here’s your dashboard at a glance.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('students').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final cgpa = data?['cgpa'] as double?;
        final attendance = data?['attendance_percentage'] as double?;

        return Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryItem('CGPA', cgpa?.toStringAsFixed(2) ?? 'N/A', Colors.blue),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                _summaryItem('Attendance', '${attendance?.toStringAsFixed(1) ?? 'N/A'}%', Colors.green),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAssignments(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('studentId', isEqualTo: uid)
          .where('isCompleted', isEqualTo: false)
          .orderBy('dueDate')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('An error occurred.', style: TextStyle(color: Colors.red));
        }

        var assignments = snapshot.data!.docs;
        if (assignments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No upcoming assignments. You\'re all caught up! 🎉',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            var assignment = assignments[index].data() as Map<String, dynamic>;
            final dueDate = assignment['dueDate'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  assignment['title'] as String? ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Due: ${dueDate != null ? dueDate.toDate().toString().split(' ')[0] : 'N/A'}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to assignment details
                },
              ),
            );
          },
        );
      },
    );
  }
}