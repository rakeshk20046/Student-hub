// manage_courses_screen.dart
import 'package:flutter/material.dart';

// A simple data model for a course
class Course {
  String id;
  String title;
  String teacherName;

  Course({
    required this.id,
    required this.title,
    required this.teacherName,
  });
}

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  // Mock data for initial display
  final List<Course> _courses = [
    Course(id: '1', title: 'Calculus I', teacherName: 'Dr. Evelyn Reed'),
    Course(id: '2', title: 'Data Structures', teacherName: 'Prof. Alan Turing'),
    Course(id: '3', title: 'World History', teacherName: 'Ms. Sarah Connor'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _teacherController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  // --- Logic for CRUD operations ---
  void _addCourse() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _courses.add(
          Course(
            id: DateTime.now().toString(),
            title: _titleController.text,
            teacherName: _teacherController.text,
          ),
        );
      });
      _resetForm();
      Navigator.of(context).pop();
      _showSnackBar('Course added successfully!');
    }
  }

  void _editCourse(Course course) {
    _titleController.text = course.title;
    _teacherController.text = course.teacherName;
    _showCourseDialog(isEdit: true, courseToEdit: course);
  }

  void _updateCourse(Course courseToEdit) {
    if (_formKey.currentState!.validate()) {
      setState(() {
        courseToEdit.title = _titleController.text;
        courseToEdit.teacherName = _teacherController.text;
      });
      _resetForm();
      Navigator.of(context).pop();
      _showSnackBar('Course updated successfully!');
    }
  }

  void _deleteCourse(Course course) {
    setState(() {
      _courses.removeWhere((item) => item.id == course.id);
    });
    _showSnackBar('Course deleted.');
  }

  void _resetForm() {
    _titleController.clear();
    _teacherController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- UI Elements ---
  void _showCourseDialog({bool isEdit = false, Course? courseToEdit}) {
    if (isEdit) {
      _titleController.text = courseToEdit!.title;
      _teacherController.text = courseToEdit.teacherName;
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
              color: const Color(0xFF1A237E), // Deep indigo background
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? 'Edit Course' : 'New Course',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Course Title',
                    icon: Icons.title,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _teacherController,
                    label: 'Teacher Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (isEdit) {
                        _updateCourse(courseToEdit!);
                      } else {
                        _addCourse();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text(isEdit ? 'Update' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        filled: true,
        fillColor: const Color(0xFF2C3E50).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a value';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      // appBar: AppBar(
      //   title: const Text(
      //     'Manage Courses',
      //     style: TextStyle(color: Colors.white),
      //   ),
      //   backgroundColor: const Color(0xFF1A237E), // Deep indigo header
      //   automaticallyImplyLeading: false,
      // ),
      body: _courses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book,
              size: 80,
              color: Colors.cyanAccent.withOpacity(0.6),
            ),
            const SizedBox(height: 20),
            const Text(
              'No courses have been added yet.',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const Text(
              'Tap the button to create a new one!',
              style: TextStyle(fontSize: 16, color: Colors.white54),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return Dismissible(
            key: Key(course.id),
            direction: DismissDirection.startToEnd,
            onDismissed: (direction) {
              _deleteCourse(course);
            },
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              color: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Teacher: ${course.teacherName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                    onPressed: () => _editCourse(course),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCourseDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}