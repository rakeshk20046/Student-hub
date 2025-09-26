import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemReportsScreen extends StatefulWidget {
  const SystemReportsScreen({super.key});

  @override
  State<SystemReportsScreen> createState() => _SystemReportsScreenState();
}

class _SystemReportsScreenState extends State<SystemReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140D2F), // <-- Add this line
      appBar: AppBar(
        title: const Text(
          'System Reports',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildReportsSection(
                'User Demographics',
                <Widget>[
                  _buildReportTile(
                    'Users by Role',
                        () async {
                      final usersByRole = await _getUsersByRole();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: usersByRole.entries.map((entry) => Text(
                          '${entry.key.toUpperCase()}: ${entry.value}',
                          style: const TextStyle(color: Colors.white70),
                        )).toList(),
                      );
                    },
                  ),
                  _buildReportTile(
                    'New Users (Last 30 Days)',
                        () async {
                      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
                      final newUsers = await _firestore
                          .collection('users')
                          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
                          .count()
                          .get();
                      return Text(
                        '${newUsers.count} new users',
                        style: const TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildReportsSection(
                'Course Statistics',
                <Widget>[
                  _buildReportTile(
                    'Courses per Teacher',
                        () async {
                      // This would require a more complex query or data aggregation.
                      // For now, it's a placeholder.
                      return const Text(
                        'Data aggregation not yet implemented.',
                        style: TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                  _buildReportTile(
                    'Most Popular Courses',
                        () async {
                      // This would require a field tracking enrollments.
                      return const Text(
                        'Data not available.',
                        style: TextStyle(color: Colors.white70),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSummaryCard() {
    return FutureBuilder<Map<String, int>>(
      future: _getSystemSummary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Text('Failed to load summary: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }

        final data = snapshot.data!;
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
                  'System Summary',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const Divider(color: Colors.white24, height: 32),
                _buildSummaryTile('Total Users', Icons.group, data['totalUsers']!),
                _buildSummaryTile('Total Students', Icons.person, data['students']!),
                _buildSummaryTile('Total Teachers', Icons.people, data['teachers']!),
                _buildSummaryTile('Total Courses', Icons.book, data['totalCourses']!),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getSystemSummary() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final studentsCount = usersSnapshot.docs.where((doc) => doc.data()['role'] == 'student').length;
    final teachersCount = usersSnapshot.docs.where((doc) => doc.data()['role'] == 'teacher').length;
    final coursesSnapshot = await _firestore.collection('courses').get();
    return {
      'totalUsers': usersSnapshot.size,
      'students': studentsCount,
      'teachers': teachersCount,
      'totalCourses': coursesSnapshot.size,
    };
  }

  Future<Map<String, int>> _getUsersByRole() async {
    final students = await _firestore.collection('users').where('role', isEqualTo: 'student').count().get();
    final teachers = await _firestore.collection('users').where('role', isEqualTo: 'teacher').count().get();
    final admins = await _firestore.collection('users').where('role', isEqualTo: 'admin').count().get();
    return {
      'student': students.count ?? 0,
      'teacher': teachers.count ?? 0,
      'admin': admins.count ?? 0,
    };
  }

  Widget _buildSummaryTile(String title, IconData icon, int count) {
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
            '$count',
            style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection(String title, List<Widget> reportTiles) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        iconColor: Colors.white70,
        collapsedIconColor: Colors.white70,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: reportTiles,
      ),
    );
  }

  Widget _buildReportTile(String title, Future<Widget> Function() contentBuilder) {
    return FutureBuilder<Widget>(
      future: contentBuilder(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            title: Text(
              'Loading...',
              style: TextStyle(color: Colors.white70),
            ),
            leading: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
          );
        }
        if (snapshot.hasError) {
          return ListTile(
            title: Text(
              'Failed to load report: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        return ListTile(
          title: Text(
            title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
          subtitle: snapshot.data,
        );
      },
    );
  }
}
