import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/content_service.dart';

class ActivityDetailsPage extends StatelessWidget {
  final Activity activity;

  const ActivityDetailsPage({super.key, required this.activity});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activity.title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal.shade50,
                      child: Icon(_getActivityIcon(activity.icon),
                          color: Colors.teal, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Descrizione dell\'Evento/Servizio',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 48),
                if (activity.mediaUrl != null &&
                    activity.mediaUrl!.isNotEmpty) ...[
                  const Text(
                    'Allegati / Locandina',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (activity.mediaType == 'pdf')
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final url = Uri.parse(activity.mediaUrl!);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Apri PDF / Scarica Locandina'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        activity.mediaUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                              child: Icon(Icons.broken_image,
                                  size: 48, color: Colors.grey)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
