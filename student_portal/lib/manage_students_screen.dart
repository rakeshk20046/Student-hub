import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Student Data Model ---
class Student {
  String id;
  String name;
  String email;
  String classId;

  Student({
    required this.id,
    required this.name,
    required this.email,
    required this.classId,
  });
}

// --- Class Data Model ---
class Class {
  String id;
  String name;
  String teacherId;

  Class({
    required this.id,
    required this.name,
    required this.teacherId,
  });
}

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  // Fake logged-in teacher ID (replace with FirebaseAuth.currentUser!.uid later)
  final String _currentTeacherId = 'teacher_001';

  // Holds students from Firestore
  List<Student> _studentsInClass = [];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  void _fetchStudents() async {
    try {
      // Find teacher’s class
      final classSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('teacherId', isEqualTo: _currentTeacherId)
          .limit(1)
          .get();

      if (classSnapshot.docs.isNotEmpty) {
        final classId = classSnapshot.docs.first.id;

        // Real-time listener for students in this class
        FirebaseFirestore.instance
            .collection('students')
            .where('classId', isEqualTo: classId)
            .snapshots()
            .listen((snapshot) {
          setState(() {
            _studentsInClass = snapshot.docs.map((doc) {
              return Student(
                id: doc.id,
                name: doc['name'],
                email: doc['email'],
                classId: doc['classId'],
              );
            }).toList();
          });
        });
      }
    } catch (e) {
      print('Error fetching students: $e');
    }
  }

  // --- Add Student (combined with your Firestore add logic) ---
  void _addStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final classSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .where('teacherId', isEqualTo: _currentTeacherId)
            .limit(1)
            .get();

        if (classSnapshot.docs.isNotEmpty) {
          final classId = classSnapshot.docs.first.id;

          // Save student to Firestore
          await FirebaseFirestore.instance.collection('students').add({
            'name': _nameController.text,
            'email': _emailController.text,
            'classId': classId,
          });

          _resetForm();
          Navigator.of(context).pop();
          _showSnackBar('✅ Student added successfully');
        }
      } catch (e) {
        _showSnackBar('❌ Failed to add student: $e');
      }
    }
  }

  // --- Edit & Update ---
  void _editStudent(Student student) {
    _nameController.text = student.name;
    _emailController.text = student.email;
    _showStudentDialog(isEdit: true, studentToEdit: student);
  }

  void _updateStudent(Student student) async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(student.id)
            .update({
          'name': _nameController.text,
          'email': _emailController.text,
        });

        _resetForm();
        Navigator.of(context).pop();
        _showSnackBar('✅ Student updated successfully');
      } catch (e) {
        _showSnackBar('❌ Failed to update student: $e');
      }
    }
  }

  // --- Delete Student ---
  void _deleteStudent(Student student) async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(student.id)
          .delete();
      _showSnackBar('🗑️ Student deleted');
    } catch (e) {
      _showSnackBar('❌ Failed to delete student: $e');
    }
  }

  // --- Helpers ---
  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- Dialog for Add/Edit ---
  void _showStudentDialog({bool isEdit = false, Student? studentToEdit}) {
    if (isEdit) {
      _nameController.text = studentToEdit!.name;
      _emailController.text = studentToEdit.email;
    } else {
      _resetForm();
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
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
                  isEdit ? 'Edit Student' : 'New Student',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'Student Name', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(_emailController, 'Student Email', Icons.email),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (isEdit) {
                      _updateStudent(studentToEdit!);
                    } else {
                      _addStudent();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(isEdit ? 'Update' : 'Add'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF1A237E),
      //   title: const Text("Manage Students"),
      // ),
      body: _studentsInClass.isEmpty
          ? const Center(
          child: Text('No students yet.',
              style: TextStyle(color: Colors.white70)))
          : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _studentsInClass.length,
          itemBuilder: (ctx, i) {
            final student = _studentsInClass[i];
            return Dismissible(
              key: Key(student.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _deleteStudent(student),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                color: const Color(0xFF1A237E),
                child: ListTile(
                  title: Text(student.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(student.email,
                      style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon:
                    const Icon(Icons.edit, color: Colors.cyanAccent),
                    onPressed: () => _editStudent(student),
                  ),
                ),
              ),
            );
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
