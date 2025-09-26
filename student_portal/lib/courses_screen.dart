import 'package:flutter/material.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < rating) {
        stars.add(const Icon(Icons.star, color: Colors.tealAccent, size: 16));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.white, size: 16));
      }
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allCourses = [
      {
        'name': 'Android Development',
        'teacher': 'Sudhanshu Rao',
        'price': '₹7000',
        'rating': 4.5,
        'image': 'assets/course_images/android dev.jpg',
      },
      {
        'name': 'Cyber Security',
        'teacher': 'Jaspreet Singh',
        'price': '₹null',
        'rating': 4.0,
        'image': 'assets/course_images/cyber-security.jpg',
      },
      {
        'name': 'Data Science',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/data-science.png',
      },
      {
        'name': 'Data Analytics',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/Data-analytics.png',
      },
      {
        'name': 'Agnetic AI',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/agentic-ai.png',
      },
      {
        'name': 'C++ / CPP',
        'teacher': 'Rahul Sharma',
        'price': '₹5000',
        'rating': 0.0,
        'image': 'assets/course_images/C++.png',
      },
      {
        'name': 'Digital marketing',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/Digital-Marketing.png',
      },
      {
        'name': 'Web Development',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/web-development.png',
      },
      {
        'name': 'Machine Learning',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/Machine-learning .png',
      },
      {
        'name': 'Python',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/Python.png',
      },
      {
        'name': 'Core Java',
        'teacher': 'Sudhanshu Kumar',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/Core-java.png',
      },
      {
        'name': 'JavaScript',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/Javascript.png',
      },
      {
        'name': 'Artificial Intelligence',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/ai.png',
      },
      {
        'name': 'Graphic Designing',
        'teacher': 'N/A',
        'price': '₹null',
        'rating': 0.0,
        'image': 'assets/course_images/graphic-s.jpg',
      },
    ];

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Courses'),
      //   automaticallyImplyLeading: false, // This removes the back button
      //   backgroundColor: Colors.black,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: Colors.black),
      //   titleTextStyle: const TextStyle(
      //       color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      // ),
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: allCourses.length,
        itemBuilder: (context, index) {
          final course = allCourses[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.black,
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset(
                  course['image'] as String,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.class_, color: Colors.white),
                    );
                  },
                ),
              ),
              title: Text(
                course['name'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course['teacher'] as String,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Row(
                    children: [
                      Text(
                        course['price'] as String,
                        style: const TextStyle(color: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      _buildRatingStars(course['rating'] as double),
                    ],
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailScreen(course: course),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}