import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/review_service.dart';

class ReviewsPage extends StatefulWidget {
  final List<ReviewModel> reviews;
  final bool isAdmin;
  final Function(String)? onApprove;
  final Function(String)? onDelete;

  const ReviewsPage({
    super.key,
    required this.reviews,
    this.isAdmin = false,
    this.onApprove,
    this.onDelete,
  });

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  late List<ReviewModel> _currentReviews;

  @override
  void initState() {
    super.initState();
    _currentReviews = List.from(widget.reviews);
  }

  void _handleApprove(String id) async {
    if (widget.onApprove != null) {
      widget.onApprove!(id);
      setState(() {
        final index = _currentReviews.indexWhere((r) => r.id == id);
        if (index != -1) {
          final r = _currentReviews[index];
          _currentReviews[index] = ReviewModel(
            id: r.id,
            name: r.name,
            rating: r.rating,
            text: r.text,
            date: r.date,
            approved: true,
          );
        }
      });
    }
  }

  void _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Recensione'),
        content: const Text('Sei sicuro di voler eliminare questa recensione?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.onDelete != null) {
      widget.onDelete!(id);
      setState(() {
        _currentReviews.removeWhere((r) => r.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutte le Recensioni'),
      ),
      body: _currentReviews.isEmpty
          ? const Center(child: Text('Nessuna recensione disponibile.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _currentReviews.length,
              itemBuilder: (context, index) {
                final review = _currentReviews[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: widget.isAdmin && !review.approved
                        ? BorderSide(color: Colors.orange.shade300, width: 2)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  review.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                if (widget.isAdmin && !review.approved) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'DA APPROVARE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
                        if (widget.isAdmin) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!review.approved)
                                TextButton.icon(
                                  onPressed: () => _handleApprove(review.id),
                                  icon: const Icon(Icons.check,
                                      color: Colors.green, size: 18),
                                  label: const Text('Approva',
                                      style: TextStyle(color: Colors.green)),
                                ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: () => _handleDelete(review.id),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red, size: 18),
                                label: const Text('Elimina',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
