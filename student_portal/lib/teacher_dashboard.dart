import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_portal/manage_assignments_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_courses_screen.dart';
import 'manage_grades_screen.dart';
import 'manage_students_screen.dart';
import 'settings_screen.dart';
import 'notification_screen.dart';
import 'student_dashboard.dart'; // Import the new attendance screen
import 'package:intl/intl.dart'; // Import for date formatting

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _TeacherHomePage(), // Set the advanced home page as the default
      const ManageCoursesScreen(),
      const ManageStudentsScreen(),
      const ManageGradesScreen(),
      const SettingsScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Teacher Hub'; // Updated default title for home page
      case 1:
        return 'Manage Courses';
      case 2:
        return 'Manage Students';
      case 3:
        return 'Manage Grades';
      case 4:
        return 'Settings';
      default:
        return 'Teacher Hub';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home), // Home icon for the dashboard
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grade),
              label: 'Grades',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.cyanAccent,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _TeacherHomePage extends StatelessWidget {
  _TeacherHomePage();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> _getTeacherDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'courses': 0, 'students': 0, 'assignments': 0, 'upcoming': 0};
    }

    final teacherCourses = await _firestore.collection('courses').where('teacherId', isEqualTo: user.uid).get();
    final totalCourses = teacherCourses.size;

    int totalStudents = 0;
    int totalAssignments = 0;
    int upcomingDeadlines = 0;

    for (var doc in teacherCourses.docs) {
      final courseId = doc.id;
      final studentsInCourse = await _firestore.collection('users').where('enrolledCourses', arrayContains: courseId).get();
      totalStudents += studentsInCourse.size;

      final assignmentsInCourse = await _firestore.collection('assignments').where('courseId', isEqualTo: courseId).get();
      totalAssignments += assignmentsInCourse.size;

      // Count upcoming deadlines for assignments
      final now = DateTime.now();
      final upcomingAssignments = assignmentsInCourse.docs.where((assignmentDoc) {
        final deadlineTimestamp = assignmentDoc.data()['deadline'] as Timestamp?;
        if (deadlineTimestamp == null) return false;
        final deadline = deadlineTimestamp.toDate();
        return deadline.isAfter(now);
      }).length;
      upcomingDeadlines += upcomingAssignments;
    }

    return {
      'courses': totalCourses,
      'students': totalStudents,
      'assignments': totalAssignments,
      'upcoming': upcomingDeadlines,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<User?>(
                future: Future.value(FirebaseAuth.instance.currentUser),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                  }
                  final user = snapshot.data;
                  final displayName = user?.displayName ?? 'Teacher';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $displayName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Here\'s a quick overview of your activities.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }),
            // Removed FutureBuilder and GridView for metric cards
            const SizedBox(height: 32),
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 16),
            // Using Wrap for quick actions for better responsiveness
            _buildQuickActions(context),
            const SizedBox(height: 32),
            _buildSectionTitle('Recent Activity (Example)'),
            const SizedBox(height: 16),
            _buildRecentActivityList(),
          ],
        ),
      ),
    );
  }

  // Removed _buildMetricCard widget as it's no longer used

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap( // Using Wrap for a more flexible layout
      spacing: 12.0, // Horizontal spacing
      runSpacing: 12.0, // Vertical spacing
      alignment: WrapAlignment.start,
      children: [
        _buildQuickActionButton(
          context,
          'Add Assignment',
          Icons.assignment_add,
          Colors.purpleAccent,
              () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageAssignmentsScreen()));
          },
        ),
        _buildQuickActionButton(
          context,
          'Enroll Student',
          Icons.person_add,
          Colors.tealAccent,
              () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageStudentsScreen()));
          },
        ),
        _buildQuickActionButton(
          context,
          'Create Course',
          Icons.add_box,
          Colors.indigoAccent,
              () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageCoursesScreen()));
          },
        ),
        _buildQuickActionButton(
          context,
          'View Grades',
          Icons.assessment,
          Colors.pinkAccent,
              () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ManageGradesScreen()));
          },
        ),
        // New Quick Action Button for Daily Attendance
        _buildQuickActionButton(
          context,
          'Attendance',
          Icons.checklist, // A suitable icon for attendance
          Colors.cyanAccent, // A distinct color
              () {
            // Navigate to the DailyAttendanceTeacherScreen
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DailyAttendanceTeacherScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox( // Wrap with SizedBox to give a fixed size
      width: 90, // Adjusted width
      child: Column(
        children: [
          Container(
            width: 50, // Smaller container
            height: 50, // Smaller container
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10), // Smaller border radius
              border: Border.all(color: color, width: 1),
            ),
            child: IconButton(
              icon: Icon(icon, color: color, size: 26), // Smaller icon size
              onPressed: onTap,
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            title,
            textAlign: TextAlign.center, // Center text for better appearance
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11, // Smaller font size
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final List<Map<String, String>> activities = [
      {'title': 'New assignment "Math Homework 3" created for Algebra I.', 'time': '2 hours ago'},
      {'title': 'Grade for "English Essay" updated for John Doe.', 'time': 'Yesterday'},
      {'title': 'New student Jane Smith enrolled in Biology II.', 'time': '2 days ago'},
      {'title': 'Deadline for "Physics Lab Report" is tomorrow.', 'time': '3 days ago'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          color: Colors.grey[850],
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activity['time']!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Dummy screen for demonstration
class DailyAttendanceTeacherScreen extends StatelessWidget {
  const DailyAttendanceTeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Attendance'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white, // Ensures the back button is visible
      ),
      body: const Center(
        child: Text(
          'This is the Daily Attendance screen for teachers.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      backgroundColor: const Color(0xFF121212), // Match dashboard background
    );
  }
}