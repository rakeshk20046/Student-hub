// manage_grades_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageGradesScreen extends StatefulWidget {
  const ManageGradesScreen({super.key});

  @override
  State<ManageGradesScreen> createState() => _ManageGradesScreenState();
}

class _ManageGradesScreenState extends State<ManageGradesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _scoreController = TextEditingController();

  String? _selectedStudentId;
  String? _selectedAssignmentId;
  String? _selectedAssignmentName;

  // Mock students (replace with Firestore query if you want dynamic)
  final List<Map<String, String>> _students = [
    {"id": "s1", "name": "Alice Smith"},
    {"id": "s2", "name": "Bob Johnson"},
    {"id": "s3", "name": "Charlie Brown"},
  ];

  // Mock assignments
  final List<Map<String, String>> _assignments = [
    {"id": "a1", "title": "Calculus Quiz 1"},
    {"id": "a2", "title": "History Essay"},
    {"id": "a3", "title": "Science Lab Report"},
  ];

  @override
  void dispose() {
    _scoreController.dispose();
    super.dispose();
  }

  // 🔹 Add grade to Firestore
  Future<void> _addGrade() async {
    if (_formKey.currentState!.validate() &&
        _selectedStudentId != null &&
        _selectedAssignmentId != null) {
      await FirebaseFirestore.instance.collection('grades').add({
        'studentId': _selectedStudentId,
        'courseId': "course1", // set actual courseId
        'courseName': "Math 101", // fetch dynamically if needed
        'assignmentId': _selectedAssignmentId,
        'assignmentName': _selectedAssignmentName,
        'overallGrade': int.parse(_scoreController.text),
        'breakdown': {
          "Score": int.parse(_scoreController.text),
        },
      });

      _resetForm();
      Navigator.of(context).pop();
      _showSnackBar('Grade added successfully!');
    }
  }

  // 🔹 Update grade
  Future<void> _updateGrade(String gradeId) async {
    await FirebaseFirestore.instance.collection('grades').doc(gradeId).update({
      'overallGrade': int.parse(_scoreController.text),
      'breakdown': {
        "Score": int.parse(_scoreController.text),
      },
    });

    _resetForm();
    Navigator.of(context).pop();
    _showSnackBar('Grade updated successfully!');
  }

  // 🔹 Delete grade
  Future<void> _deleteGrade(String gradeId) async {
    await FirebaseFirestore.instance.collection('grades').doc(gradeId).delete();
    _showSnackBar('Grade deleted.');
  }

  void _resetForm() {
    _scoreController.clear();
    _selectedStudentId = null;
    _selectedAssignmentId = null;
    _selectedAssignmentName = null;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showGradeDialog({bool isEdit = false, String? gradeId, int? score}) {
    if (isEdit && score != null) {
      _scoreController.text = score.toString();
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Edit Grade' : 'New Grade',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Student dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedStudentId,
                    decoration: _inputDecoration("Select Student", Icons.person),
                    items: _students.map((student) {
                      return DropdownMenuItem<String>(
                        value: student["id"],
                        child: Text(student["name"]!),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedStudentId = val),
                    validator: (value) =>
                    value == null ? 'Please select a student' : null,
                  ),
                  const SizedBox(height: 16),

                  // Assignment dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedAssignmentId,
                    decoration:
                    _inputDecoration("Select Assignment", Icons.assignment),
                    items: _assignments.map((assignment) {
                      return DropdownMenuItem<String>(
                        value: assignment["id"],
                        child: Text(assignment["title"]!),
                        onTap: () {
                          _selectedAssignmentName = assignment["title"];
                        },
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAssignmentId = val),
                    validator: (value) =>
                    value == null ? 'Please select an assignment' : null,
                  ),
                  const SizedBox(height: 16),

                  // Score input
                  TextFormField(
                    controller: _scoreController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration("Enter Score", Icons.score),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          int.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      if (isEdit) {
                        _updateGrade(gradeId!);
                      } else {
                        _addGrade();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                    ),
                    child: Text(isEdit ? "Update Grade" : "Add Grade"),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.cyanAccent),
      filled: true,
      fillColor: const Color(0xFF2C3E50),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // appBar: AppBar(
      //   title: const Text("Manage Grades"),
      //   backgroundColor: const Color(0xFF1A237E),
      // ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('grades').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var grades = snapshot.data!.docs;

          if (grades.isEmpty) {
            return const Center(
                child: Text("No grades yet.",
                    style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            itemCount: grades.length,
            itemBuilder: (context, index) {
              var grade = grades[index];
              var gradeData = grade.data() as Map<String, dynamic>;

              return Card(
                color: const Color(0xFF1A237E),
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(
                    gradeData['assignmentName'] ?? "Unnamed",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Student: ${gradeData['studentId']} | Score: ${gradeData['overallGrade']}%",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                        onPressed: () => _showGradeDialog(
                          isEdit: true,
                          gradeId: grade.id,
                          score: gradeData['overallGrade'],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteGrade(grade.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGradeDialog(),
        backgroundColor: Colors.cyanAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
