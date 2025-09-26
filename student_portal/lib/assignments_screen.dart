import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

// ---
// Assignment Data Model
// This class will hold all the necessary information for a single assignment.
class Assignment {
  String id;
  String title;
  String subject;
  String teacher;
  String dueDate;
  IconData icon;
  Color color;
  AssignmentStatus status;

  Assignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.teacher,
    required this.dueDate,
    required this.icon,
    required this.color,
    this.status = AssignmentStatus.todo,
  });
}

// Assignment Status Enum
enum AssignmentStatus { todo, inProcess, completed }

// ---
// Mock "Backend" / State Management
// This class simulates a backend that stores and manages assignments.
// We use a ValueNotifier to automatically notify listeners (like AssignmentsScreen)
// when the data changes, which triggers a UI rebuild.
class AssignmentManager extends ValueNotifier<List<Assignment>> {
  AssignmentManager() : super([]);

  // Mock a database call to add a new assignment
  void addAssignment(Assignment newAssignment) {
    value = [...value, newAssignment];
  }

  // Update the status of an existing assignment
  void updateAssignmentStatus(String assignmentId, AssignmentStatus newStatus) {
    final updatedList = value.map((assignment) {
      if (assignment.id == assignmentId) {
        return Assignment(
          id: assignment.id,
          title: assignment.title,
          subject: assignment.subject,
          teacher: assignment.teacher,
          dueDate: assignment.dueDate,
          icon: assignment.icon,
          color: assignment.color,
          status: newStatus,
        );
      }
      return assignment;
    }).toList();
    value = updatedList;
  }
}

final assignmentManager = AssignmentManager();

// ---
// Main App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ---
// Home Page
// This page lists the available courses and navigates to the enrollment screen.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy course data
    final courses = [
      {
        'id': 'C101',
        'name': 'Introduction to Flutter',
        'teacher': 'Mr. P.R. Singh',
        'price': '499.00',
      },
      {
        'id': 'C102',
        'name': 'Web Development Fundamentals',
        'teacher': 'Mrs. L. Sharma',
        'price': '349.00',
      },
      {
        'id': 'C103',
        'name': 'Data Science for Beginners',
        'teacher': 'Dr. S. K. Gupta',
        'price': '599.00',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Courses'),
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Card(
            color: Colors.grey[900],
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['name']!,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Instructor: ${course['teacher']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Price: ₹${course['price']}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EnrollmentScreen(course: course),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enroll Now',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Bottom navigation bar to switch between screens
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AssignmentsScreen()),
            );
          }
        },
      ),
    );
  }
}

// ---
// Enrollment Screen
// This screen handles the payment flow and now also creates a new assignment.
class EnrollmentScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const EnrollmentScreen({super.key, required this.course});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _upiIdController = TextEditingController();
  bool _isProcessingPayment = false;
  late Razorpay _razorpay;
  String? _selectedPaymentMethod;

  bool _isPostPaymentProcessing = false;
  Map<String, dynamic>? _invoiceData;
  Map<String, dynamic>? _idCardData;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _enrollUserInCourse();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful! Processing your enrollment...')),
    );
    _handlePostPaymentTasks();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
    setState(() {
      _isProcessingPayment = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> _initiatePaymentFlow() async {
    final List<String> upiPaymentMethods = ['Google Pay', 'PhonePe', 'Paytm', 'Amazon Pay', 'Other UPI Apps'];

    if (upiPaymentMethods.contains(_selectedPaymentMethod) && _upiIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your UPI ID.')),
      );
      return;
    }

    if (!upiPaymentMethods.contains(_selectedPaymentMethod) && (_fullNameController.text.isEmpty || _emailController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    final options = {
      'key': 'd5zXz33vuLUpFzs9J79mxp4G',
      'amount': (double.parse(widget.course['price']) * 100).toInt(),
      'name': 'Student Hub',
      'description': 'Enrollment for ${widget.course['name']}',
      'prefill': upiPaymentMethods.contains(_selectedPaymentMethod)
          ? {'contact': '9876543210', 'email': _emailController.text, 'vpa': _upiIdController.text}
          : {'contact': '9876543210', 'email': _emailController.text},
      'currency': 'INR',
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Razorpay error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment gateway error. Please try again.')),
      );
      setState(() {
        _isProcessingPayment = false;
      });
    }
  }

  Future<void> _enrollUserInCourse() async {
    final courseId = widget.course['id'];
    print('User enrolled in course: $courseId');
  }

  Widget _buildPaymentOption(String title, String imagePath) {
    bool isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Image.network(
              imagePath,
              width: 40,
              height: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePostPaymentTasks() async {
    setState(() {
      _isPostPaymentProcessing = true;
    });

    final userData = {
      'fullName': _fullNameController.text.isEmpty ? 'John Doe' : _fullNameController.text,
      'email': _emailController.text.isEmpty ? 'johndoe@example.com' : _emailController.text,
      'courseName': widget.course['name'],
      'coursePrice': widget.course['price'],
    };

    final invoicePdf = await _createInvoicePdf(userData);
    final invoiceFilePath = await _downloadInvoice(invoicePdf, 'invoice.pdf');
    _sendInvoiceEmail(userData, invoiceFilePath);

    final idCardData = {
      'name': userData['fullName'],
      'course': userData['courseName'],
      'id': 'ID-${DateTime.now().millisecondsSinceEpoch}',
      'enrollmentDate': DateTime.now().toLocal().toString().split(' ')[0],
    };

    // ** New Logic: Create an assignment and add it to the manager **
    final newAssignment = Assignment(
      id: idCardData['id']!,
      title: '${widget.course['name']} Final Assignment',
      subject: widget.course['name']!,
      teacher: widget.course['teacher']!,
      dueDate: 'Due: Dec 31',
      icon: Icons.assignment_outlined,
      color: Colors.deepPurple.shade200,
    );
    assignmentManager.addAssignment(newAssignment);

    setState(() {
      _invoiceData = userData;
      _idCardData = idCardData;
      _isPostPaymentProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrollment completed! Invoice and ID Card are ready.')),
    );
  }

  Future<Uint8List> _createInvoicePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Student: ${data['fullName']}'),
              pw.Text('Course: ${data['courseName']}'),
              pw.Text('Amount: ${data['coursePrice']} INR'),
              pw.SizedBox(height: 10),
              pw.Text('Thank you for your purchase!', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  Future<String> _downloadInvoice(Uint8List pdfData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);

    print('Invoice downloaded to: ${file.path}');
    return file.path;
  }

  void _sendInvoiceEmail(Map<String, dynamic> data, String filePath) {
    print('Simulating sending invoice to ${data['email']} from a backend service.');
  }

  Widget _buildIdCard() {
    if (_idCardData == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student ID Card',
              style: TextStyle(
                color: Colors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white54),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.white, size: 60),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _idCardData!['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _idCardData!['course'],
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${_idCardData!['id']}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Enrolled: ${_idCardData!['enrollmentDate']}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> upiPaymentMethods = ['Google Pay', 'PhonePe', 'Paytm', 'Amazon Pay', 'Other UPI Apps'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enroll in Course'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPostPaymentProcessing
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                'Completing enrollment...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        )
            : _idCardData != null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enrollment Complete!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildIdCard(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  print('Downloading invoice...');
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Download Invoice',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Your Enrollment',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Course: ${widget.course['name']}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Instructor: ${widget.course['teacher']}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              'Price: ${widget.course['price']}',
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
            const Divider(color: Colors.grey, height: 32),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              'Google Pay',
              'https://placehold.co/40x40/green/white?text=GPay',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'PhonePe',
              'https://placehold.co/40x40/green/white?text=PhonePe',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'Paytm',
              'https://placehold.co/40x40/green/white?text=Paytm',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'Amazon Pay',
              'https://placehold.co/40x40/green/white?text=AmazonPay',
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              'Other UPI Apps',
              'https://placehold.co/40x40/green/white?text=UPI',
            ),
            const SizedBox(height: 32),
            if (_selectedPaymentMethod != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (upiPaymentMethods.contains(_selectedPaymentMethod))
                    TextFormField(
                      controller: _upiIdController,
                      decoration: const InputDecoration(
                        labelText: 'Enter UPI ID',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    )
                  else
                    Column(
                      children: [
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white70),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            const Spacer(),
            if (_selectedPaymentMethod != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessingPayment ? null : _initiatePaymentFlow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessingPayment
                      ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : const Text(
                    'Pay and Enroll',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---
// Assignments Screen
// This screen now dynamically displays assignments and allows for status updates.
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  @override
  void initState() {
    super.initState();
    // Rebuild the UI whenever the assignment list changes
    assignmentManager.addListener(_onAssignmentsUpdated);
  }

  @override
  void dispose() {
    assignmentManager.removeListener(_onAssignmentsUpdated);
    super.dispose();
  }

  void _onAssignmentsUpdated() {
    setState(() {});
  }

  void _handleAcceptAssignment(Assignment assignment) {
    assignmentManager.updateAssignmentStatus(assignment.id, AssignmentStatus.inProcess);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${assignment.title} is now in process!')),
    );
  }

  void _handleSubmitAssignment(Assignment assignment) {
    // Simulating a PDF submission. In a real app, you would
    // use a file picker package here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulating submission of ${assignment.title}...')),
    );

    // After a short delay to simulate upload, update the status
    Future.delayed(const Duration(seconds: 2), () {
      assignmentManager.updateAssignmentStatus(assignment.id, AssignmentStatus.completed);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${assignment.title} submitted successfully!')),
      );
    });
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        color: Colors.grey[900],
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: assignment.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      assignment.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Subject: ${assignment.subject}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teacher: ${assignment.teacher}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        assignment.dueDate,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (assignment.status == AssignmentStatus.todo)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () => _handleAcceptAssignment(assignment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Accept Assignment',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )
              else if (assignment.status == AssignmentStatus.inProcess)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ElevatedButton(
                    onPressed: () => _handleSubmitAssignment(assignment),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter assignments based on their status
    final todoAssignments = assignmentManager.value.where((a) => a.status == AssignmentStatus.todo).toList();
    final inProcessAssignments = assignmentManager.value.where((a) => a.status == AssignmentStatus.inProcess).toList();
    final completedAssignments = assignmentManager.value.where((a) => a.status == AssignmentStatus.completed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todoAssignments.isNotEmpty) ...[
              const Text('New Assignments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.grey),
              ...todoAssignments.map(_buildAssignmentCard).toList(),
              const SizedBox(height: 20),
            ],
            if (inProcessAssignments.isNotEmpty) ...[
              const Text('In Process', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.grey),
              ...inProcessAssignments.map(_buildAssignmentCard).toList(),
              const SizedBox(height: 20),
            ],
            if (completedAssignments.isNotEmpty) ...[
              const Text('Completed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const Divider(color: Colors.grey),
              ...completedAssignments.map(_buildAssignmentCard).toList(),
              const SizedBox(height: 20),
            ],
            if (assignmentManager.value.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No assignments found.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Enroll in a course to receive an assignment.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
