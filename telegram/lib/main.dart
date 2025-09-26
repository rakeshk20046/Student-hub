import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swipe_cards/swipe_cards.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DatingApp());
}

class DatingApp extends StatelessWidget {
  const DatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dating App",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.pink,
          elevation: 1,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

//////////////////////////////////////////////////////
// AUTH GATE – Redirects user to Login/Signup if not authenticated
//////////////////////////////////////////////////////
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const MainScreen();
        }
        return const LoginPage();
      },
    );
  }
}

//////////////////////////////////////////////////////
// LOGIN PAGE
//////////////////////////////////////////////////////
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                );
              },
              child: const Text("Don't have an account? Sign up"),
            )
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// SIGNUP PAGE
//////////////////////////////////////////////////////
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'name': _nameCtrl.text.trim(),
        'age': int.tryParse(_ageCtrl.text.trim()) ?? 0,
        'bio': _bioCtrl.text.trim(),
        'photoUrl': '',
        'createdAt': Timestamp.now(),
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: _ageCtrl, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
              TextField(controller: _bioCtrl, decoration: const InputDecoration(labelText: "Bio")),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email")),
              TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Sign Up"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
                child: const Text("Already have an account? Login"),
              )
            ],
          ),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// MAIN SCREEN (Your existing code)
//////////////////////////////////////////////////////
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = const [DiscoverScreen(), MatchesScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
//////////////////////////////////////////////////////
// DISCOVER SCREEN (Swipe Cards)
//////////////////////////////////////////////////////
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late MatchEngine _matchEngine;
  List<SwipeItem> _swipeItems = [];
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUid)
        .get();

    users = snapshot.docs.map((doc) => doc.data()).toList();

    _swipeItems = users.map((user) {
      return SwipeItem(
        content: user,
        likeAction: () => _likeUser(user['uid']),
        nopeAction: () {},
      );
    }).toList();

    setState(() {
      _matchEngine = MatchEngine(swipeItems: _swipeItems);
    });
  }

  Future<void> _likeUser(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('likes').doc(currentUserId).set({
      'likedUsers': FieldValue.arrayUnion([otherUserId]),
    }, SetOptions(merge: true));

    final otherDoc =
    await FirebaseFirestore.instance.collection('likes').doc(otherUserId).get();

    if (otherDoc.exists &&
        (otherDoc['likedUsers'] as List).contains(currentUserId)) {
      await FirebaseFirestore.instance.collection('matches').add({
        'users': [currentUserId, otherUserId],
        'createdAt': Timestamp.now(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_swipeItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Discover")),
      body: Center(
        child: SwipeCards(
          matchEngine: _matchEngine,
          itemBuilder: (context, index) {
            final user = _swipeItems[index].content as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  user['photoUrl'] != null && user['photoUrl'] != ''
                      ? Image.network(user['photoUrl'], height: 250, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 120, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text("${user['name']}, ${user['age']}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(user['bio'] ?? "",
                      style: const TextStyle(fontSize: 16, color: Colors.black54)),
                ],
              ),
            );
          },
          onStackFinished: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("No more users")));
          },
          upSwipeAllowed: false,
          fillSpace: true,
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////
// MATCHES SCREEN
//////////////////////////////////////////////////////
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Matches")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('users', arrayContains: currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final matches = snapshot.data!.docs;

          if (matches.isEmpty) {
            return const Center(child: Text("No matches yet ❤️"));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final users = matches[index]['users'] as List;
              final otherUserId = users.firstWhere((id) => id != currentUid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const ListTile(title: Text("Loading..."));
                  final user = userSnap.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: user['photoUrl'] != null && user['photoUrl'] != ''
                        ? CircleAvatar(backgroundImage: NetworkImage(user['photoUrl']))
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['name']),
                    subtitle: Text(user['bio'] ?? ""),
                    onTap: () {
                      // TODO: open chat screen
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////
// PROFILE SCREEN
//////////////////////////////////////////////////////
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>> _getUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUser(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                user['photoUrl'] != null && user['photoUrl'] != ''
                    ? CircleAvatar(radius: 50, backgroundImage: NetworkImage(user['photoUrl']))
                    : const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40)),
                const SizedBox(height: 20),
                Text(user['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text("Age: ${user['age']}"),
                Text(user['bio'] ?? ""),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

