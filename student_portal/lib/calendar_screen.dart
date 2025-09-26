import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This example is designed to show the UI without dummy data,
    // as per the request. The UI is structured to easily
    // accommodate a dynamic list of assignments later.

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Calendar'),
      //   automaticallyImplyLeading: false,
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      // ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // This section would be replaced with a ListView.builder
            // showing assignments once data is available.
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'No upcoming tasks.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Assignments will appear here with their due dates.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
