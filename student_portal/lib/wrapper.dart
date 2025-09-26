import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'welcome_screen.dart';
import 'student_dashboard.dart';
import 'teacher_dashboard.dart';
import 'admin_dashboard.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Listen for auth state changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Show a loading indicator while checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If a user is logged in, check their role
        if (authSnapshot.hasData && authSnapshot.data != null) {
          final user = authSnapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userSnapshot) {
              // Show a loading indicator while fetching user data
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final role = userData?['role'];

                // 3. Navigate to the correct dashboard based on role
                switch (role) {
                  case 'student':
                    return const StudentDashboard();
                  case 'teacher':
                    return const TeacherDashboard();
                  case 'admin':
                    return const AdminDashboard();
                  default:
                  // If role is not found, log out and go back to welcome screen
                    FirebaseAuth.instance.signOut();
                    return const WelcomeScreen();
                }
              }

              // If user document doesn't exist, log them out
              FirebaseAuth.instance.signOut();
              return const WelcomeScreen();
            },
          );
        }

        // If no user is logged in, show the welcome screen
        return const WelcomeScreen();
      },
    );
  }
}