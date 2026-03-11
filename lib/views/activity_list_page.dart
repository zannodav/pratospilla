import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'activity_details_page.dart';

class AllActivitiesPage extends StatelessWidget {
  final List<Activity> activities;

  const AllActivitiesPage({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutte le attività'),
      ),
      body: activities.isEmpty
          ? const Center(child: Text('Nessuna attività disponibile.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityDetailsPage(activity: activity),
                        ),
                      );
                    },
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left side: Media preview (or icon if no media)
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                            child: _buildMediaPreview(activity),
                          ),
                          // Right side: Text description
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    activity.title.isNotEmpty
                                        ? activity.title
                                        : 'Attività',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    activity.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMediaPreview(Activity activity) {
    const double size = 130.0; // Dimensione quadrata per l'immagine

    if (activity.mediaUrl != null && activity.mediaUrl!.isNotEmpty) {
      if (activity.mediaType == 'pdf') {
        return Container(
          width: size,
          color: Colors.red.shade50,
          child: const Center(
            child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
          ),
        );
      } else {
        return Image.network(
          activity.mediaUrl!,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(activity.icon, size),
        );
      }
    }
    return _buildFallbackIcon(activity.icon, size);
  }

  Widget _buildFallbackIcon(String iconName, double size) {
    return Container(
      width: size,
      color: Colors.teal.shade50,
      child: Center(
        child: Icon(
          _getActivityIcon(iconName),
          size: 48,
          color: Colors.teal,
        ),
      ),
    );
  }

  IconData _getActivityIcon(String iconName) {
    switch (iconName) {
      case 'hiking':
        return Icons.hiking;
      case 'pedal_bike':
        return Icons.pedal_bike;
      case 'festival':
        return Icons.festival;
      case 'water':
        return Icons.water;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_activity':
        return Icons.local_activity;
      default:
        return Icons.star;
    }
  }
}
