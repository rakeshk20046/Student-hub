import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_portal/welcome_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // State variables to manage the form.
  bool isTeacher = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // New state variables to store the values
  String _subjects = '';
  String _courseName = '';

  String? _formMessage;
  bool _isLoading = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _schoolNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // The submit function handles form validation, user registration, and data storage.
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _formMessage = "Error: Passwords do not match.";
        });
        return;
      }

      setState(() {
        _formMessage = null;
        _isLoading = true;
      });

      try {
        // Create user with email and password
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user != null) {
          final userId = user.uid;

          // Gather form data into a map
          final formData = <String, dynamic>{
            'role': isTeacher ? 'teacher' : 'student',
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'schoolName': _schoolNameController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          };

          if (isTeacher) {
            formData['subjects'] = _subjects;
          } else {
            formData['courseName'] = _courseName;
          }

          // Save additional user information to Firestore
          await _firestore.collection('users').doc(userId).set(formData);

          // Navigate directly to the dashboard based on the role
          if (isTeacher) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const TeacherDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const StudentDashboard()),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _formMessage = 'Error: ${e.message}';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _formMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF140D2F), // Dark purple
                Color(0xFF2C1951), // Slightly lighter purple
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  color: Colors.white.withOpacity(0.1), // Semi-transparent card
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          const Text(
                            'Create Your Account',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Join as a student or a teacher.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Role Selector
                          _buildRoleSelector(),
                          const SizedBox(height: 24),

                          // Form Fields
                          _buildTextField(
                            controller: _firstNameController,
                            labelText: 'First Name',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _lastNameController,
                            labelText: 'Last Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            labelText: 'Email Address',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _schoolNameController,
                            labelText: 'School Name',
                            icon: Icons.school,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            icon: Icons.lock,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 16),

                          // Conditional Fields based on role
                          if (isTeacher)
                            _buildTextFieldWithCallback(
                              labelText: 'Subject(s) Taught',
                              hintText: 'e.g., Math, Science',
                              icon: Icons.class_,
                              onChanged: (value) => _subjects = value,
                            ),
                          if (!isTeacher)
                            _buildTextFieldWithCallback(
                              labelText: 'Course Name',
                              hintText: 'e.g., Organic Chemistry 101',
                              icon: Icons.school,
                              onChanged: (value) => _courseName = value,
                            ),
                          const SizedBox(height: 16),

                          // Form Message Area
                          if (_formMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                _formMessage!,
                                style: TextStyle(
                                  color: _formMessage!.contains("Error")
                                      ? Colors.redAccent
                                      : Colors.lightGreenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Submit Button and loading indicator
                          _buildSubmitButton(),

                          const SizedBox(height: 16),

                          // Login Button
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => const WelcomeScreen(),
                              ));
                            },
                            child: const Text(
                              'Already have an account? Login here.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build TextFields with validation and icons.
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFBA68C8),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFBA68C8)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $labelText.';
        }
        return null;
      },
    );
  }

  // New helper widget to build TextFields that update state variables
  Widget _buildTextFieldWithCallback({
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      enabled: !_isLoading,
      style: const TextStyle(color: Colors.white),
      cursorColor: const Color(0xFFBA68C8),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white30),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFBA68C8)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $labelText.';
        }
        return null;
      },
    );
  }

  // Helper widget to build the role selector.
  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildRoleButton('Student', !isTeacher),
          Switch(
            value: isTeacher,
            onChanged: _isLoading ? null : (value) {
              setState(() {
                isTeacher = value;
              });
            },
            activeThumbColor: const Color(0xFFF06292),
            activeTrackColor: const Color(0xFFBA68C8),
            inactiveThumbColor: const Color(0xFFBA68C8),
            inactiveTrackColor: Colors.white.withOpacity(0.3),
          ),
          _buildRoleButton('Teacher', isTeacher),
        ],
      ),
    );
  }

  // Helper widget for role selector buttons.
  Widget _buildRoleButton(String title, bool isSelected) {
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : Colors.white54,
      ),
    );
  }

  // Helper widget for the submit button with loading indicator.
  Widget _buildSubmitButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF06292),
            Color(0xFFBA68C8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBA68C8).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
