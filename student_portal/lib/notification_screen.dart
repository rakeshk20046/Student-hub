import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

const String __app_id = '1:240243879202:ios:5ce820bfc107ab31e0c97b';
const String __firebase_config = '{}';
const String __initial_auth_token = '';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> setupFlutterNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        if (notificationResponse.payload != null) {
          debugPrint('notification payload: ${notificationResponse.payload}');
        }
      });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
  });
}

void showFlutterNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;

  flutterLocalNotificationsPlugin.show(
    notification.hashCode,
    notification.title,
    notification.body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        icon: '@mipmap/ic_launcher',
      ),
    ),
    payload: message.data['assignmentId'] ?? message.data['gradeId'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final firebaseConfigMap =
        json.decode(__firebase_config) as Map<String, dynamic>;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseConfigMap['apiKey'] as String,
          appId: firebaseConfigMap['appId'] as String,
          messagingSenderId: firebaseConfigMap['messagingSenderId'] as String,
          projectId: firebaseConfigMap['projectId'] as String,
        ),
      );
    }
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await setupFlutterNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notifications',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      home: const NotificationPage(),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _signInAndFetchRole();
    _handleFCM();
  }

  Future<void> _signInAndFetchRole() async {
    try {
      await _auth.signInAnonymously();

      _auth.authStateChanges().listen((User? user) async {
        setState(() {
          _user = user;
        });

        if (user != null) {
          final userDoc =
          await _firestore.collection('users').doc(user.uid).get();
          final userData = userDoc.data();
          if (userDoc.exists && userData != null && userData.containsKey('role')) {
            setState(() {
              _userRole = userData['role'] as String;
            });
            debugPrint('User role is: $_userRole');
          }
          _saveFCMToken(user.uid);
        }
      });
    } catch (e) {
      print('Failed to sign in or fetch role: $e');
    }
  }

  Future<void> _saveFCMToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _firestore
          .collection('users')
          .doc(userId)
          .set({'fcmToken': token}, SetOptions(merge: true));
      debugPrint('FCM Token saved for user: $userId');
    }
  }

  void _handleFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New Notification: ${message.notification!.title}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _toggleReadStatus(String docId, bool currentStatus) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(docId)
          .update({
        'isRead': !currentStatus,
      });
    } catch (e) {
      print('Error updating notification: $e');
    }
  }

  Future<void> _deleteNotification(String docId) async {
    if (_user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('notifications')
          .doc(docId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Widget _buildTrailingWidget(String docId, bool isRead) {
    switch (_userRole) {
      case 'student':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _toggleReadStatus(docId, isRead),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRead ? Colors.grey : Colors.green,
                shape: const StadiumBorder(),
              ),
              child: Text(isRead ? 'Unread' : 'Read',
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _deleteNotification(docId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: const StadiumBorder(),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 'teacher':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                _deleteNotification(docId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: const StadiumBorder(),
              ),
              child: const Text('Dismiss', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      case 'admin':
        return Row(
          mainAxisSize: MainAxisSize.min, // Corrected from `MainAxisSize.AxisSize`
          children: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Viewing system log...')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: const StadiumBorder(),
              ),
              child: const Text('View Log', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null || _userRole == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final notificationsPath = 'users/${_user!.uid}/notifications';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(notificationsPath)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('You have no notifications.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] as bool? ?? false;
              final message = data['message'] as String? ?? 'No message';
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: isRead ? TextDecoration.lineThrough : null,
                      color: isRead ? Colors.grey.shade600 : Colors.black87,
                    ),
                  ),
                  subtitle: timestamp != null
                      ? Text(
                    DateFormat.yMd().add_Hms().format(timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  )
                      : null,
                  trailing: _buildTrailingWidget(doc.id, isRead),
                ),
              );
            },
          );
        },
      ),
    );
  }
}