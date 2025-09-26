import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  String? _selectedCourseId;
  String? _selectedCourseName;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grades'),
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('students').doc(user.uid).snapshots(),
            builder: (context, studentSnapshot) {
              if (!studentSnapshot.hasData || studentSnapshot.data!.data() == null) {
                return const SizedBox.shrink();
              }
              var studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
              var courseIds = List<String>.from(studentData['course_ids'] ?? []);

              if (courseIds.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<List<DocumentSnapshot>>(
                future: _getCourseDetails(courseIds),
                builder: (context, courseSnapshot) {
                  if (!courseSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  var courses = courseSnapshot.data!;

                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: DropdownButton<String>(
                      hint: const Text('Select Class'),
                      value: _selectedCourseId,
                      items: courses.map((courseDoc) {
                        var courseData = courseDoc.data() as Map<String, dynamic>;
                        return DropdownMenuItem<String>(
                          value: courseDoc.id,
                          child: Text(courseData['name'] as String),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCourseId = newValue;
                          _selectedCourseName = courses.firstWhere((doc) => doc.id == newValue).get('name');
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('students').doc(user.uid).snapshots(),
        builder: (context, studentSnapshot) {
          if (!studentSnapshot.hasData || studentSnapshot.data!.data() == null) {
            return const Center(child: CircularProgressIndicator());
          }
          var studentData = studentSnapshot.data!.data() as Map<String, dynamic>;
          final studentName = studentData['name'] ?? 'Student';
          final schoolName = studentData['school'] ?? 'No School Listed';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $studentName',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schoolName,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getGradesStream(user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var grades = snapshot.data!.docs;
                    if (grades.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.grade,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _selectedCourseName != null
                                  ? 'No grades available for $_selectedCourseName.'
                                  : 'No grades available yet.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Your grades will appear here once they are added by a teacher.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: grades.length,
                      itemBuilder: (context, index) {
                        var gradeData = grades[index].data() as Map<String, dynamic>;
                        Color gradeColor = _getGradeColor(gradeData['overallGrade']?.toDouble());
                        String gradeLetter = _getGradeLetter(gradeData['overallGrade']?.toDouble());

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: gradeColor.withOpacity(0.2),
                              child: Text(
                                gradeLetter,
                                style: TextStyle(
                                  color: gradeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              gradeData['assignmentName'] ?? 'Unnamed Assignment',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Course: ${gradeData['courseName']}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            trailing: Text(
                              '${gradeData['overallGrade'] ?? 'N/A'}%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: gradeColor,
                              ),
                            ),
                            children: [
                              ..._buildGradeBreakdown(gradeData['breakdown']),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getGradesStream(String userId) {
    if (_selectedCourseId != null) {
      return FirebaseFirestore.instance
          .collection('grades')
          .where('studentId', isEqualTo: userId)
          .where('courseId', isEqualTo: _selectedCourseId)
          .snapshots();
    }
    return FirebaseFirestore.instance
        .collection('grades')
        .where('studentId', isEqualTo: userId)
        .snapshots();
  }

  Future<List<DocumentSnapshot>> _getCourseDetails(List<String> courseIds) async {
    if (courseIds.isEmpty) return [];
    List<Future<DocumentSnapshot>> futures = [];
    for (var id in courseIds) {
      futures.add(FirebaseFirestore.instance.collection('courses').doc(id).get());
    }
    return Future.wait(futures);
  }

  List<Widget> _buildGradeBreakdown(dynamic breakdown) {
    if (breakdown == null || breakdown.isEmpty) {
      return [const Padding(padding: EdgeInsets.all(16.0), child: Text('No grade breakdown available.'))];
    }
    List<Widget> breakdownWidgets = [];
    (breakdown as Map<String, dynamic>).forEach((key, value) {
      breakdownWidgets.add(
        ListTile(
          title: Text(key),
          trailing: Text('${value.toString()}%'),
        ),
      );
    });
    return breakdownWidgets;
  }

  Color _getGradeColor(double? grade) {
    if (grade == null) return Colors.grey;
    if (grade >= 90) return Colors.green.shade600;
    if (grade >= 80) return Colors.lightGreen.shade600;
    if (grade >= 70) return Colors.orange.shade600;
    if (grade >= 60) return Colors.deepOrange.shade600;
    return Colors.red.shade600;
  }

  String _getGradeLetter(double? grade) {
    if (grade == null) return 'N/A';
    if (grade >= 90) return 'A';
    if (grade >= 80) return 'B';
    if (grade >= 70) return 'C';
    if (grade >= 60) return 'D';
    return 'F';
  }
}
