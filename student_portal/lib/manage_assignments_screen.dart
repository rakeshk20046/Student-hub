import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // Import for File

// --------------------
// Data Models
// --------------------
class Assignment {
  String id;
  String title;
  String course;
  DateTime dueDate;
  String classId;
  List<StudentSubmission> submissions;
  // New: Optional file associated with the assignment itself (e.g., instructions)
  String? assignmentFileUrl;

  Assignment({
    required this.id,
    required this.title,
    required this.course,
    required this.dueDate,
    required this.classId,
    this.submissions = const [],
    this.assignmentFileUrl,
  });
}

class StudentSubmission {
  String studentName;
  // Updated: Changed fileUrl to be nullable for initial state
  String? fileUrl;
  bool isChecked;
  String feedback;

  StudentSubmission({
    required this.studentName,
    this.fileUrl, // Now nullable
    this.isChecked = false,
    this.feedback = "",
  });
}

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

// For demonstration, let's create a mock list of assignments a teacher would see
List<Assignment> mockAssignments = [
  Assignment(
    id: 'a1',
    title: 'Math Homework 1',
    course: 'Algebra I',
    dueDate: DateTime.now().add(const Duration(days: 7)),
    classId: 'class101',
    assignmentFileUrl: null, // Teacher might not upload a file for every assignment
    submissions: [
      StudentSubmission(
        studentName: "Alice",
        fileUrl: "mock_files/alice_math_hw1.pdf", // Mock path for demo
        isChecked: false,
        feedback: "",
      ),
      StudentSubmission(
        studentName: "Bob",
        fileUrl: "mock_files/bob_math_hw1.docx",
        isChecked: true,
        feedback: "Good work!",
      ),
    ],
  ),
  Assignment(
    id: 'a2',
    title: 'History Essay',
    course: 'World History',
    dueDate: DateTime.now().add(const Duration(days: 14)),
    classId: 'class101',
    assignmentFileUrl: "mock_files/essay_instructions.pdf",
    submissions: [], // No submissions yet for this one
  ),
];


// --------------------
// Manage Assignments (Landing)
// --------------------
class ManageAssignmentsScreen extends StatelessWidget {
  const ManageAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // appBar: AppBar(
      //   title: const Text("Assignments", style: TextStyle(color: Colors.white)),
      //   backgroundColor: const Color(0xFF1A237E),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionCard(
              context,
              title: "📄 Make Assignment",
              subtitle: "Create and assign new work to your class.",
              icon: Icons.upload_file,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const NewAssignmentScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildOptionCard(
              context,
              title: "✅ Check Assignments",
              subtitle: "Review student submissions and give feedback.",
              icon: Icons.assignment_turned_in,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CheckAssignmentsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context,
      {required String title,
        required String subtitle,
        required IconData icon,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF1A237E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: Colors.cyanAccent.withOpacity(0.3),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, color: Colors.cyanAccent, size: 40),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.cyanAccent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------
// New Assignment Screen
// --------------------
class NewAssignmentScreen extends StatefulWidget {
  const NewAssignmentScreen({super.key});

  @override
  State<NewAssignmentScreen> createState() => _NewAssignmentScreenState();
}

class _NewAssignmentScreenState extends State<NewAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _courseController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedFilePath; // To store the path of the uploaded file

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File selected: ${result.files.single.name}")),
      );
    } else {
      // User canceled the picker
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File selection cancelled.")),
      );
    }
  }

  void _saveAssignment() {
    if (_formKey.currentState!.validate()) {
      // In a real app, you'd upload _selectedFilePath to storage
      // and get a URL, then create an Assignment object.
      // For now, we'll just show the path and add to mockAssignments.

      Assignment newAssignment = Assignment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        course: _courseController.text,
        dueDate: _selectedDate,
        classId: "class101", // Example, would come from selected class
        assignmentFileUrl: _selectedFilePath, // Store the path/URL
      );
      mockAssignments.add(newAssignment); // Add to our mock list

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Assignment created successfully!")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.cyanAccent, // Header background color
            onPrimary: Colors.black, // Header text color
            surface: Color(0xFF1A237E), // Body background color
            onSurface: Colors.white, // Body text color
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.cyanAccent, // Button text color
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title:
        const Text("New Assignment", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration("Assignment Title", Icons.title),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                value!.isEmpty ? "Enter assignment title" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _courseController,
                decoration: _inputDecoration("Course Name", Icons.book),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                value!.isEmpty ? "Enter course name" : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                onTap: _pickDate,
                leading: const Icon(Icons.calendar_today,
                    color: Colors.cyanAccent),
                title: Text(
                  "Due Date: ${_selectedDate.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_selectedFilePath != null
                    ? "File Selected: ${_selectedFilePath!.split('/').last}"
                    : "Upload Assignment File"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              if (_selectedFilePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Selected: ${_selectedFilePath!.split('/').last}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveAssignment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Save Assignment",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.cyanAccent),
      filled: true,
      fillColor: const Color(0xFF2C3E50).withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.white30),
      ),
    );
  }
}

// --------------------
// Check Assignments Screen
// --------------------
class CheckAssignmentsScreen extends StatefulWidget {
  const CheckAssignmentsScreen({super.key});

  @override
  State<CheckAssignmentsScreen> createState() =>
      _CheckAssignmentsScreenState();
}

class _CheckAssignmentsScreenState extends State<CheckAssignmentsScreen> {
  Assignment? _selectedAssignment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title:
        const Text("Check Assignments", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A237E),
        // If an assignment is selected, show back button to list of assignments
        leading: _selectedAssignment != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _selectedAssignment = null;
            });
          },
        )
            : null,
      ),
      body: _selectedAssignment == null
          ? _buildAssignmentList()
          : _buildSubmissionList(_selectedAssignment!),
    );
  }

  Widget _buildAssignmentList() {
    if (mockAssignments.isEmpty) {
      return const Center(
          child: Text("No assignments created yet.",
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: mockAssignments.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final assignment = mockAssignments[index];
        return Card(
          color: const Color(0xFF1A237E),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(assignment.title,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(
                "Course: ${assignment.course}\nDue: ${assignment.dueDate.toLocal().toString().split(' ')[0]}",
                style: const TextStyle(color: Colors.white70)),
            trailing: const Icon(Icons.arrow_forward_ios,
                color: Colors.cyanAccent),
            onTap: () {
              setState(() {
                _selectedAssignment = assignment;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildSubmissionList(Assignment assignment) {
    if (assignment.submissions.isEmpty) {
      return const Center(
          child: Text("No student submissions for this assignment yet.",
              style: TextStyle(color: Colors.white70)));
    }
    return ListView.builder(
      itemCount: assignment.submissions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final sub = assignment.submissions[index];
        return Card(
          color: const Color(0xFF1A237E),
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(sub.studentName,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(
                "File: ${sub.fileUrl != null ? sub.fileUrl!.split('/').last : 'N/A'}\nFeedback: ${sub.feedback}",
                style: const TextStyle(color: Colors.white70)),
            trailing: Wrap(
              spacing: 10,
              children: [
                if (sub.fileUrl != null) // Only show download if a file exists
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.cyanAccent),
                    onPressed: () => _downloadFile(sub.fileUrl!),
                  ),
                IconButton(
                  icon: Icon(
                    sub.isChecked
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: sub.isChecked ? Colors.green : Colors.white70,
                  ),
                  onPressed: () => _toggleChecked(sub),
                ),
                IconButton(
                  icon: const Icon(Icons.feedback, color: Colors.cyanAccent),
                  onPressed: () => _giveFeedback(sub),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleChecked(StudentSubmission submission) {
    setState(() {
      submission.isChecked = !submission.isChecked;
    });
    // In a real app, update this state in your backend
  }

  void _giveFeedback(StudentSubmission submission) {
    TextEditingController feedbackCtrl =
    TextEditingController(text: submission.feedback);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        title:
        const Text("Give Feedback", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: feedbackCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Write feedback...",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF2C3E50).withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white30),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                submission.feedback = feedbackCtrl.text;
              });
              Navigator.pop(context);
              // In a real app, save feedback to your backend
            },
            child: const Text("Save", style: TextStyle(color: Colors.cyanAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(String fileUrl) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Simulating download of: ${fileUrl.split('/').last}")),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Extract just the filename from the mock URL
      final fileName = fileUrl.split('/').last;
      final localPath = '${directory.path}/$fileName';
      final file = File(localPath);

      // Ensure the file exists (create it if it doesn't for the mock)
      if (!await file.exists()) {
        await file.writeAsString("This is a mock file content for $fileName");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File downloaded to: $localPath")),
      );

      // In a real application, you would now use a package like `open_filex`
      // to open the downloaded file.
      // e.g., await OpenFilex.open(localPath);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error simulating file download: $e")),
      );
    }
  }
}