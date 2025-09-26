import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:student_portal/welcome_screen.dart';
import 'package:student_portal/academic_progress_screen.dart';
import 'package:student_portal/student_management_screen.dart';
import 'package:student_portal/user_management_screen.dart';
import 'package:student_portal/system_reports_screen.dart';
import 'package:student_portal/update_profile_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // Import for date formatting

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isUploading = false;

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('From Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('From Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    final user = FirebaseAuth.instance.currentUser;

    if (pickedFile != null && user != null) {
      setState(() {
        _isUploading = true;
      });

      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child(user.uid)
            .child('${DateTime.now().toIso8601String()}_profile_image.jpg');

        final uploadTask = storageRef.putFile(File(pickedFile.path));
        final snapshot = await uploadTask.whenComplete(() {});

        final downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
        });

        print('Image uploaded and profile updated with URL: $downloadUrl');
      } catch (e) {
        print('Error uploading image or updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in to delete.')),
      );
      return;
    }

    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmDelete) {
      return;
    }

    try {
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userData.exists) {
        final profileImageUrl = userData.data()?['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          final storageRef = FirebaseStorage.instance.refFromURL(profileImageUrl);
          await storageRef.delete();
          print('Profile image deleted from Storage.');
        }
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
      print('User data deleted from Firestore.');

      await user.delete();
      print('User deleted from Firebase Auth.');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error deleting account: $e');
      String errorMessage = 'Failed to delete account. Please re-authenticate and try again.';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'This operation is sensitive and requires recent authentication. Please log out and log in again, then try deleting your account.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('General Error deleting account: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF140D2F),
        iconTheme: const IconThemeData(color: Colors.white), // For back button
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF140D2F), Color(0xFF2C1951)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter)),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting || _isUploading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('User data not found.', style: TextStyle(color: Colors.white)));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role'];
            final firstName = userData['firstName'] ?? 'User';
            final lastName = userData['lastName'] ?? '';
            final email = userData['email'] ?? '';
            final profileImageUrl = userData['profileImageUrl'];

            // --- Fix for enrollmentDate ---
            String enrollmentDateDisplay = 'N/A';
            if (userData.containsKey('enrollmentDate') && userData['enrollmentDate'] is Timestamp) {
              final Timestamp enrollmentTimestamp = userData['enrollmentDate'];
              final DateTime enrollmentDateTime = enrollmentTimestamp.toDate();
              enrollmentDateDisplay = DateFormat('yyyy-MM-dd').format(enrollmentDateTime);
            }

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24), // Adjusted for app bar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                          child: profileImageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.white70) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white, size: 24),
                              onPressed: () {
                                _showImageSourceActionSheet(context);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '$firstName $lastName',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 10,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.person,
                              title: 'Role',
                              subtitle: role ?? 'N/A',
                            ),
                            const Divider(color: Colors.white12, height: 24),
                            if (role == 'student')
                              ...[
                                _buildInfoTile(
                                  icon: Icons.school,
                                  title: 'School',
                                  subtitle: userData['schoolName'] ?? 'N/A',
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                _buildInfoTile(
                                  icon: Icons.book,
                                  title: 'Course',
                                  subtitle: userData['courseName'] ?? 'N/A',
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                _buildInfoTile(
                                  icon: Icons.calendar_today,
                                  title: 'Enrollment Date',
                                  subtitle: enrollmentDateDisplay, // Use the formatted date
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                // Removed Student ID, Address, and Phone Number fields
                                _buildOptionTile(
                                  context,
                                  icon: Icons.insights,
                                  title: 'View Academic Progress',
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AcademicProgressScreen()));
                                  },
                                ),
                              ],
                            if (role == 'teacher')
                              ...[
                                _buildInfoTile(
                                  icon: Icons.school,
                                  title: 'School',
                                  subtitle: userData['schoolName'] ?? 'N/A',
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                _buildInfoTile(
                                  icon: Icons.class_,
                                  title: 'Course Name',
                                  subtitle: userData['courseName'] ?? 'N/A',
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                _buildOptionTile(
                                  context,
                                  icon: Icons.group,
                                  title: 'Manage Students',
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentManagementScreen()));
                                  },
                                ),
                              ],
                            if (role == 'admin')
                              ...[
                                _buildInfoTile(
                                  icon: Icons.admin_panel_settings,
                                  title: 'Admin Status',
                                  subtitle: 'Full Access',
                                ),
                                const Divider(color: Colors.white12, height: 24),
                                _buildOptionTile(
                                  context,
                                  icon: Icons.group,
                                  title: 'Manage All Users',
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()));
                                  },
                                ),
                                _buildOptionTile(
                                  context,
                                  icon: Icons.analytics,
                                  title: 'View System Reports',
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemReportsScreen()));
                                  },
                                ),
                              ],
                            const Divider(color: Colors.white12, height: 24),
                            _buildOptionTile(
                              context,
                              icon: Icons.edit,
                              title: 'Update Profile',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const UpdateProfileScreen()));
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _deleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                (Route<dynamic> route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        foregroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.blueAccent),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyanAccent.withOpacity(0.8)),
      title: Text(
        title,
        style: TextStyle(color: Colors.cyanAccent.withOpacity(0.8), fontWeight: FontWeight.bold),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }
}