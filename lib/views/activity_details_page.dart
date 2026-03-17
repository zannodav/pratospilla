import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/content_service.dart';
import '../widgets/pdf_viewer.dart';

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
                    _buildPdfSection(context, activity.mediaUrl!)
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

  Widget _buildPdfSection(BuildContext context, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Inline PDF preview (web only via iframe)
        if (isPdfViewerSupported) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: buildPdfViewer(url, height: 700),
          ),
          const SizedBox(height: 12),
        ],
        // Download / open button (always shown)
        OutlinedButton.icon(
          onPressed: () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          icon: const Icon(Icons.open_in_new, color: Colors.red),
          label: const Text(
            'Apri PDF in nuova scheda',
            style: TextStyle(color: Colors.red),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
      ],
    );
  }
}
