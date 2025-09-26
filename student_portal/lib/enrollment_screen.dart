import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data'; // Added this import to fix the Uint8List error

// --- Main function for testing purposes ---
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock course data for testing
    final Map<String, dynamic> mockCourse = {
      'id': 'C001',
      'name': 'Introduction to Flutter',
      'teacher': 'Dr. Angela Yu',
      'price': '999.00', // Ensure price is a string that can be parsed to double
    };

    return MaterialApp(
      title: 'Student Hub Enrollment',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark, // Set dark theme for better visibility with black background
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.green, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white70),
          ),
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      home: EnrollmentScreen(course: mockCourse),
    );
  }
}
// --- End of Main function for testing purposes ---


class EnrollmentScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const EnrollmentScreen({super.key, required this.course});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _upiIdController = TextEditingController(); // For UPI apps
  bool _isProcessingPayment = false;
  late Razorpay _razorpay;
  String? _selectedPaymentMethod;

  // New state variables for post-payment tasks
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

    // Prefill email if needed for testing (can be removed in production)
    _emailController.text = 'test@example.com';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _upiIdController.dispose();
    _razorpay.clear(); // Important to clear listeners
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _enrollUserInCourse();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful! Processing your enrollment...')),
    );
    // Start post-payment tasks
    _handlePostPaymentTasks();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    String errorMessage = 'Payment failed: ${response.code} - ${response.message}';
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = 'Payment cancelled by user.';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
    setState(() {
      _isProcessingPayment = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet selected: ${response.walletName}')),
    );
  }

  Future<void> _initiatePaymentFlow() async {
    // Basic validation before initiating payment
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name.')),
      );
      return;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }
    // No UPI ID validation needed since all specific payment options are removed.

    setState(() {
      _isProcessingPayment = true;
    });

    // Prepare prefill data dynamically
    Map<String, String> prefillData = {
      'contact': '9876543210', // Mock contact number
      'email': _emailController.text,
    };

    final options = {
      'key': 'rzp_test_RM89v8vda95Hyp', // <<< IMPORTANT: Replace with your actual Test Key
      'amount': (double.parse(widget.course['price']) * 100).toInt(), // amount in paise
      'name': 'Student Hub',
      'description': 'Enrollment for ${widget.course['name']}',
      'prefill': prefillData,
      'currency': 'INR', // Or the appropriate currency code
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
    // Here you would typically send data to your backend to confirm enrollment
    // and update your database.
  }

  // This is a new function to handle all post-payment tasks
  Future<void> _handlePostPaymentTasks() async {
    setState(() {
      _isPostPaymentProcessing = true;
    });

    // Mock fetching user data from a "database" or using current input
    final userData = {
      'fullName': _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Enrolled Student', // Use actual name if entered
      'email': _emailController.text,
      'courseName': widget.course['name'],
      'coursePrice': widget.course['price'],
    };

    // 1. Generate Invoice PDF
    final invoicePdf = await _createInvoicePdf(userData);
    final invoiceFilePath = await _downloadInvoice(invoicePdf, 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');

    // 2. Send invoice email (mocked)
    _sendInvoiceEmail(userData, invoiceFilePath);

    // 3. Create ID Card (mocked)
    final idCardData = {
      'name': userData['fullName'],
      'course': userData['courseName'],
      'id': 'SH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', // Simple mock ID
      'enrollmentDate': DateTime.now().toLocal().toString().split(' ')[0],
    };

    setState(() {
      _invoiceData = userData; // Storing invoice data to display if needed
      _idCardData = idCardData;
      _isPostPaymentProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enrollment completed! Invoice and ID Card are ready.')),
    );
  }

  // Creates the invoice PDF
  Future<Uint8List> _createInvoicePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Student Hub Invoice', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey500),
              pw.SizedBox(height: 10),
              pw.Text('Date: ${DateTime.now().toLocal().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 20),
              pw.Text('Student Name: ${data['fullName']}', style: const pw.TextStyle(fontSize: 16)),
              pw.Text('Email: ${data['email']}', style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text('Course: ${data['courseName']}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Amount Paid: INR ${data['coursePrice']}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
              pw.SizedBox(height: 30),
              pw.Text('Thank you for your enrollment!', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
              pw.Text('For any queries, contact support@studenthub.com', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  // Saves the invoice to the device and provides a download link
  Future<String> _downloadInvoice(Uint8List pdfData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfData);
      print('Invoice downloaded to: ${file.path}');

      // Optionally, you can open the file immediately after download
      // await OpenFile.open(file.path); // Requires 'open_file' package

      return file.path;
    } catch (e) {
      print('Error saving invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save invoice.')),
      );
      return ''; // Return empty path on error
    }
  }

  // Simulates sending an invoice via email
  void _sendInvoiceEmail(Map<String, dynamic> data, String filePath) {
    // This part requires a backend service to securely send emails.
    // In a real application, you would make an HTTP call to your server here.
    print('Simulating sending invoice to ${data['email']} with file $filePath via a backend service.');
    // Example of a placeholder API call:
    // http.post(
    //   Uri.parse('https://your-backend.com/send-invoice'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: json.encode({'email': data['email'], 'invoicePath': filePath}),
    // );
  }

  // Builds the ID card widget
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
            : _idCardData != null // After successful post-payment tasks, show ID card and invoice download
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
                onPressed: () async {
                  // Re-create invoice for download if _invoiceData is available
                  if (_invoiceData != null) {
                    final invoicePdf = await _createInvoicePdf(_invoiceData!);
                    await _downloadInvoice(invoicePdf, 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice data not available.')),
                    );
                  }
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate back or to a home screen
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.home, color: Colors.green),
                label: const Text(
                  'Go to Home',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Colors.green),
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
              'Price: INR ${widget.course['price']}',
              style: const TextStyle(color: Colors.green, fontSize: 18),
            ),
            const Divider(color: Colors.grey, height: 32),
            const Text(
              'Your Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
            ),
            const Spacer(), // Pushes the button to the bottom
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