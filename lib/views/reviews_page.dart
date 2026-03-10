import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/review_service.dart';

class ReviewsPage extends StatelessWidget {
  final List<ReviewModel> reviews;

  const ReviewsPage({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutte le Recensioni'),
      ),
      body: reviews.isEmpty
          ? const Center(child: Text('Nessuna recensione disponibile.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              DateFormat('MMMM yyyy', 'it').format(review.date),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(
                            review.rating,
                            (_) => Icon(Icons.star,
                                color: Colors.amber.shade600, size: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          review.text,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
