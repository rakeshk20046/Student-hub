import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_portal/settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';// Make sure this path is correct

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      _AdminHomePage(onNavigate: _setSelectedIndex),
      const _UserManagementPage(),
      const _CourseManagementPage(), // This is where we will modify
      const _ReportsPage(),
      const SettingsScreen(),
    ];
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onBottomBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Admin Dashboard';
      case 1:
        return 'User Management';
      case 2:
        return 'Course Management';
      case 3:
        return 'Analytics & Reports';
      case 4:
        return 'Settings';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: const Color(0xFF140D2F),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF140D2F), Color(0xFF2C1951)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFFBA68C8),
        unselectedItemColor: Colors.white54,
        onTap: _onBottomBarTapped,
        backgroundColor: const Color(0xFF140D2F),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class _AdminHomePage extends StatelessWidget {
  final Function(int) onNavigate;

  const _AdminHomePage({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Admin',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Users',
                    collection: 'users',
                    icon: Icons.person_outline,
                    color: Colors.lightBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Courses',
                    collection: 'courses',
                    icon: Icons.library_books_outlined,
                    color: Colors.lightGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              title: 'Manage Users',
              subtitle: 'View and manage student, teacher, and admin accounts.',
              icon: Icons.group,
              color: Colors.blueAccent,
              onTap: () => onNavigate(1),
            ),
            _buildActionCard(
              title: 'Manage Courses',
              subtitle: 'Add, edit, or delete courses and view enrollment.',
              icon: Icons.library_books,
              color: Colors.greenAccent,
              onTap: () => onNavigate(2),
            ),
            _buildActionCard(
              title: 'View Reports',
              subtitle: 'Access system analytics and comprehensive reports.',
              icon: Icons.analytics,
              color: Colors.orangeAccent,
              onTap: () => onNavigate(3),
            ),
            _buildActionCard(
              title: 'Settings',
              subtitle: 'Configure app settings, notifications, and security.',
              icon: Icons.settings,
              color: Colors.purpleAccent,
              onTap: () => onNavigate(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String collection,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          color: Colors.transparent,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 50),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'live count',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.transparent,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 45),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserManagementPage extends StatelessWidget {
  const _UserManagementPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              final String? profileImageUrl = userData['profilePictureUrl'];

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl)
                            : null,
                        backgroundColor: Colors.white12,
                        child: profileImageUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${userData['firstName']} ${userData['lastName']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Role: ${userData['role']}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios,
                            color: Colors.white54, size: 16),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _UserAnalyticsPage(
                                userId: userId,
                                userData: userData,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserAnalyticsPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const _UserAnalyticsPage({
    required this.userId,
    required this.userData,
  });

  @override
  State<_UserAnalyticsPage> createState() => _UserAnalyticsPageState();
}

class _UserAnalyticsPageState extends State<_UserAnalyticsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<int>> _getAdminAnalytics() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final coursesSnapshot = await _firestore.collection('courses').get();
    return [usersSnapshot.size, coursesSnapshot.size];
  }

  Future<int> _getStudentCoursesEnrolledCount(String studentId) async {
    final userSnapshot = await _firestore.collection('users').doc(studentId).get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      final enrolledCourses = userData?['enrolledCourses'] as List<dynamic>?;
      return enrolledCourses?.length ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final String? profileImageUrl = widget.userData['profilePictureUrl'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userData['firstName']} ${widget.userData['lastName']}\'s Analytics'),
        backgroundColor: const Color(0xFF140D2F),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF140D2F), Color(0xFF2C1951)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(
                'User Information',
                [
                  'Full Name: ${widget.userData['firstName']} ${widget.userData['lastName']}',
                  'Email: ${widget.userData['email']}',
                  'Role: ${widget.userData['role']}',
                  'Joined: ${widget.userData['createdAt'] != null ? (widget.userData['createdAt'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}',
                ],
                profileImageUrl: profileImageUrl,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView( // Added to prevent overflow if content is long
                  child: Column(
                    children: [
                      _buildRoleSpecificAnalytics(),
                      if (widget.userData['role'] == 'student' && (widget.userData['enrolledCourses'] as List? ?? []).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildStudentIdCard(
                          context,
                          firstName: widget.userData['firstName'],
                          lastName: widget.userData['lastName'],
                          userId: widget.userId,
                          email: widget.userData['email'],
                          profileImageUrl: profileImageUrl,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSpecificAnalytics() {
    switch (widget.userData['role']) {
      case 'student':
        return FutureBuilder<int>(
          future: _getStudentCoursesEnrolledCount(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }
            final coursesEnrolled = snapshot.data ?? 0;
            return _buildInfoCard(
              'Student Analytics',
              [
                'Courses Enrolled: $coursesEnrolled',
                'Assignments Completed: 0',
                'Average Grade: N/A',
              ],
            );
          },
        );
      case 'teacher':
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('courses').where('teacherId', isEqualTo: widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }

            final courses = snapshot.data?.docs ?? [];
            final courseNames =
            courses.map((c) => c['name'] as String? ?? 'Unnamed').toList();

            return _buildInfoCard(
              'Teacher Analytics',
              [
                'Courses Taught: ${courses.length}',
                ...courseNames.map((name) => '📘 $name'),
              ],
            );
          },
        );
      case 'admin':
        return FutureBuilder<List<int>>(
          future: _getAdminAnalytics(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
            }
            final totalUsers = snapshot.data?[0] ?? 0;
            final totalCourses = snapshot.data?[1] ?? 0;
            return _buildInfoCard(
              'Admin Analytics',
              [
                'Total Users: $totalUsers',
                'Total Courses: $totalCourses',
              ],
            );
          },
        );
      default:
        return Container();
    }
  }

  Widget _buildInfoCard(String title, List<String> details, {String? profileImageUrl}) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profileImageUrl != null) ...[
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profileImageUrl),
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                detail,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentIdCard(
      BuildContext context, {
        required String firstName,
        required String lastName,
        required String userId,
        required String email,
        String? profileImageUrl,
      }) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(0),
      color: Colors.white.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF3A2D5C), Color(0xFF6A5ACD)], // A slightly different gradient for the ID card
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Student ID Card',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white24,
              backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
              child: profileImageUrl == null
                  ? const Icon(Icons.person, size: 70, color: Colors.white70)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              '$firstName $lastName'.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Student ID: ${userId.substring(0, 8).toUpperCase()}', // Shorten ID for display
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Email: $email',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'STATUS: ENROLLED',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // You can add more elements like a barcode or QR code here
            // For example:
            // BarcodeWidget(
            //   data: userId,
            //   barcode: Barcode.code128(),
            //   color: Colors.white,
            //   width: 200,
            //   height: 60,
            //   drawText: false,
            // ),
          ],
        ),
      ),
    );
  }
}

class _CourseManagementPage extends StatefulWidget {
  const _CourseManagementPage();

  @override
  State<_CourseManagementPage> createState() => _CourseManagementPageState();
}

class _CourseManagementPageState extends State<_CourseManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of initial courses to potentially add
  final List<Map<String, dynamic>> initialCourses = [
    {
      'name': 'Android Development',
      'teacher': 'Sudhanshu Rao',
      'price': '₹7000',
      'rating': 4.5,
      'image': 'assets/course_images/android dev.jpg',
    },
    {
      'name': 'Cyber Security',
      'teacher': 'Jaspreet Singh',
      'price': '₹null',
      'rating': 4.0,
      'image': 'assets/course_images/cyber-security.jpg',
    },
    {
      'name': 'Data Science',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/data-science.png',
    },
    {
      'name': 'Data Analytics',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/Data-analytics.png',
    },
    {
      'name': 'Agentic AI',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/agentic-ai.png',
    },
    {
      'name': 'C++ / CPP',
      'teacher': 'Rahul Sharma',
      'price': '₹5000',
      'rating': 0.0,
      'image': 'assets/course_images/C++.png',
    },
    {
      'name': 'Digital marketing',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/Digital-Marketing.png',
    },
    {
      'name': 'Web Development',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/web-development.png',
    },
    {
      'name': 'Machine Learning',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/Machine-learning .png',
    },
    {
      'name': 'Python',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/Python.png',
    },
    {
      'name': 'Core Java',
      'teacher': 'Sudhanshu Kumar',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/Core-java.png',
    },
    {
      'name': 'JavaScript',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/Javascript.png',
    },
    {
      'name': 'Artificial Intelligence',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/ai.png',
    },
    {
      'name': 'Graphic Designing',
      'teacher': 'N/A',
      'price': '₹null',
      'rating': 0.0,
      'image': 'assets/course_images/graphic-s.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();
    _populateCoursesIfEmpty(); // Call this when the widget is initialized
  }

  // A method to populate courses if the 'courses' collection is empty
  Future<void> _populateCoursesIfEmpty() async {
    final coursesSnapshot = await _firestore.collection('courses').get();
    if (coursesSnapshot.docs.isEmpty) {
      for (var courseData in initialCourses) {
        await _firestore.collection('courses').add({
          'name': courseData['name'],
          'teacher': courseData['teacher'],
          'price': courseData['price'],
          'rating': courseData['rating'],
          'image': courseData['image'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // You might want to show a success message or refresh the UI here
      setState(() {}); // Refresh the UI to show the newly added courses
    }
  }

  Future<int> _getStudentsEnrolled(String courseId) async {
    final snapshot = await _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('enrolledCourses', arrayContains: courseId)
        .get();
    return snapshot.size;
  }

  Future<void> _showAddEditCourseDialog({DocumentSnapshot? course}) async {
    final isEditing = course != null;
    final courseId = isEditing ? course.id : '';
    final TextEditingController nameController = TextEditingController(text: isEditing ? course!['name'] : '');
    final TextEditingController teacherController = TextEditingController(text: isEditing ? course!['teacher'] : '');
    final TextEditingController priceController = TextEditingController(text: isEditing ? course!['price'] : '');
    final TextEditingController ratingController = TextEditingController(text: isEditing ? (course!['rating']?.toString() ?? '0.0') : '0.0');
    final TextEditingController imageController = TextEditingController(text: isEditing ? course!['image'] : '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF140D2F),
          title: Text(isEditing ? 'Edit Course' : 'Add New Course', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBA68C8)),
                    ),
                  ),
                ),
                TextField(
                  controller: teacherController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Teacher Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBA68C8)),
                    ),
                  ),
                ),
                TextField(
                  controller: priceController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBA68C8)),
                    ),
                  ),
                  keyboardType: TextInputType.text, // Price might include currency symbols
                ),
                TextField(
                  controller: ratingController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Rating (e.g., 4.5)',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBA68C8)),
                    ),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: imageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Image Path/URL',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFBA68C8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA68C8),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
              onPressed: () {
                final double? rating = double.tryParse(ratingController.text);
                if (isEditing) {
                  _updateCourse(
                    courseId,
                    nameController.text,
                    teacherController.text,
                    priceController.text,
                    rating ?? 0.0,
                    imageController.text,
                  );
                } else {
                  _addCourse(
                    nameController.text,
                    teacherController.text,
                    priceController.text,
                    rating ?? 0.0,
                    imageController.text,
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addCourse(String name, String teacher, String price, double rating, String image) async {
    if (name.isNotEmpty) {
      await _firestore.collection('courses').add({
        'name': name,
        'teacher': teacher,
        'price': price,
        'rating': rating,
        'image': image,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _updateCourse(String id, String name, String teacher, String price, double rating, String image) async {
    if (name.isNotEmpty) {
      await _firestore.collection('courses').doc(id).update({
        'name': name,
        'teacher': teacher,
        'price': price,
        'rating': rating,
        'image': image,
      });
    }
  }

  Future<void> _deleteCourse(String id) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF140D2F),
          title: const Text('Confirm Deletion', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this course?', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
              onPressed: () async {
                await _firestore.collection('courses').doc(id).delete();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Added Scaffold here
      backgroundColor: Colors.transparent, // Or your desired background color
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditCourseDialog(),
        backgroundColor: const Color(0xFFBA68C8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row( // Changed to const as there's no dynamic content
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manage Courses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                // Removed ElevatedButton here
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('courses').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No courses found.', style: TextStyle(color: Colors.white70)));
                  }

                  final courses = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final courseData = course.data() as Map<String, dynamic>;
                      final courseId = course.id;
                      final String imageUrl = courseData['image'] ?? 'assets/course_images/default.png';

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade700,
                                      child: const Icon(Icons.broken_image, color: Colors.white54),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      courseData['name'] ?? 'Unnamed Course',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Teacher: ${courseData['teacher'] ?? 'N/A'}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    Text(
                                      'Price: ${courseData['price'] ?? 'N/A'}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    Text(
                                      'Rating: ${courseData['rating']?.toStringAsFixed(1) ?? '0.0'}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    FutureBuilder<int>(
                                      future: _getStudentsEnrolled(courseId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text('Enrolled: Loading...', style: TextStyle(color: Colors.white70, fontSize: 14));
                                        }
                                        if (snapshot.hasError) {
                                          return const Text('Enrolled: Error', style: TextStyle(color: Colors.red, fontSize: 14));
                                        }
                                        return Text(
                                          'Enrolled: ${snapshot.data ?? 0} students',
                                          style: const TextStyle(
                                              color: Colors.white70, fontSize: 14),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.lightBlueAccent),
                                    onPressed: () => _showAddEditCourseDialog(course: course),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteCourse(courseId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsPage extends StatefulWidget {
  const _ReportsPage();

  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<_ReportsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, int>> _getEnrollmentData() async {
    final coursesSnapshot = await _firestore.collection('courses').get();
    Map<String, int> enrollmentCounts = {};

    for (var courseDoc in coursesSnapshot.docs) {
      final courseId = courseDoc.id;
      final courseName = courseDoc['name'] ?? 'Unknown Course';
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('enrolledCourses', arrayContains: courseId)
          .get();
      enrollmentCounts[courseName] = usersSnapshot.size;
    }
    return enrollmentCounts;
  }

  Future<Map<String, int>> _getRoleDistribution() async {
    final usersSnapshot = await _firestore.collection('users').get();
    Map<String, int> roleCounts = {
      'student': 0,
      'teacher': 0,
      'admin': 0,
      'other': 0,
    };

    for (var userDoc in usersSnapshot.docs) {
      final role = userDoc['role'] as String? ?? 'other';
      roleCounts.update(role, (value) => value + 1, ifAbsent: () => 1);
    }
    return roleCounts;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Analytics & Reports',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildReportCard(
              title: 'Course Enrollment Trends',
              child: FutureBuilder<Map<String, int>>(
                future: _getEnrollmentData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No enrollment data available.',
                            style: TextStyle(color: Colors.white70)));
                  }

                  final data = snapshot.data!;
                  final List<BarChartGroupData> barGroups = [];
                  int i = 0;
                  data.forEach((courseName, count) {
                    barGroups.add(
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: count.toDouble(),
                            color: Colors.purpleAccent.withOpacity(0.7),
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    );
                    i++;
                  });

                  return SizedBox(
                    height: 250,
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                // Corrected signature
                                final courseNames = data.keys.toList();
                                if (value.toInt() >= 0 &&
                                    value.toInt() < courseNames.length) {
                                  // return SideTitleWidget(
                                  //   axisSide:
                                  //   meta.axisSide, // Access from meta
                                  //   space: 4,
                                  //   child: Text(
                                  //     courseNames[value.toInt()],
                                  //     style: const TextStyle(
                                  //         color: Colors.white70, fontSize: 10),
                                  //     textAlign: TextAlign.center,
                                  //   ),
                                  // );
                                }
                                return const Text('');
                              },
                              reservedSize: 40,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                // Corrected signature
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.white.withOpacity(0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2), width: 1),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildReportCard(
              title: 'User Role Distribution',
              child: FutureBuilder<Map<String, int>>(
                future: _getRoleDistribution(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.values.every((element) => element == 0)) {
                    return const Center(
                        child: Text('No user role data available.',
                            style: TextStyle(color: Colors.white70)));
                  }

                  final data = snapshot.data!;
                  final List<PieChartSectionData> sections = [];
                  final colors = [
                    Colors.lightBlueAccent,
                    Colors.greenAccent,
                    Colors.orangeAccent,
                    Colors.redAccent,
                  ];
                  int colorIndex = 0;

                  data.forEach((role, count) {
                    if (count > 0) {
                      sections.add(
                        PieChartSectionData(
                          color: colors[colorIndex % colors.length],
                          value: count.toDouble(),
                          title: '$role\n(${count})',
                          radius: 80,
                          titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          titlePositionPercentageOffset: 0.55,
                        ),
                      );
                      colorIndex++;
                    }
                  });

                  return SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        borderData: FlBorderData(show: false),
                        pieTouchData: PieTouchData(touchCallback:
                            (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              return;
                            }
                          });
                        }),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({required String title, required Widget child}) {
    return Card(
      elevation: 4,
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}