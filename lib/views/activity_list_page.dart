import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'activity_details_page.dart';

class AllActivitiesPage extends StatefulWidget {
  final List<Activity> activities;
  final bool isAdmin;
  final Function(String)? onDelete;
  final Function(Activity)? onToggleVisibility;
  final Function(Activity, int)? onToggleOrder;

  const AllActivitiesPage({
    super.key,
    required this.activities,
    this.isAdmin = false,
    this.onDelete,
    this.onToggleVisibility,
    this.onToggleOrder,
  });

  @override
  State<AllActivitiesPage> createState() => _AllActivitiesPageState();
}

class _AllActivitiesPageState extends State<AllActivitiesPage> {
  late List<Activity> _currentActivities;

  @override
  void initState() {
    super.initState();
    _currentActivities = List.from(widget.activities);
  }

  void _handleDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Attività'),
        content: const Text('Sei sicuro di voler eliminare questa attività?'),
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
        _currentActivities.removeWhere((a) => a.id == id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutte le attività'),
      ),
      body: _currentActivities.isEmpty
          ? const Center(child: Text('Nessuna attività disponibile.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _currentActivities.length,
              itemBuilder: (context, index) {
                final activity = _currentActivities[index];
                return Stack(
                  children: [
                    Card(
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
                        child: Opacity(
                          opacity: activity.isVisible ? 1.0 : 0.5,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        if (widget.isAdmin && !activity.isVisible)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Text(
                                              'NASCOSTO',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.isAdmin)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: IconButton(
                                icon: Icon(
                                  activity.isVisible
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: activity.isVisible
                                      ? Colors.teal
                                      : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  if (widget.onToggleVisibility != null) {
                                    widget.onToggleVisibility!(activity);
                                    setState(() {
                                      final idx = _currentActivities.indexWhere(
                                          (a) => a.id == activity.id);
                                      if (idx != -1) {
                                        final a = _currentActivities[idx];
                                        _currentActivities[idx] = Activity(
                                          id: a.id,
                                          title: a.title,
                                          description: a.description,
                                          icon: a.icon,
                                          date: a.date,
                                          mediaUrl: a.mediaUrl,
                                          mediaType: a.mediaType,
                                          isVisible: !a.isVisible,
                                        );
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.onToggleOrder != null) ...[
                              CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.low_priority,
                                      color: Colors.teal, size: 20),
                                  onPressed: () => _showOrderDialog(context, activity),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _handleDelete(activity.id),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  void _showOrderDialog(BuildContext context, Activity item) {
    final controller =
        TextEditingController(text: item.orderIndex.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Imposta Ordine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Inserisci un numero per ordinare l\'attività (numeri più bassi appaiono per primi).'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Indice Ordine',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final newOrder = int.tryParse(controller.text) ?? item.orderIndex;
              if (widget.onToggleOrder != null) {
                widget.onToggleOrder!(item, newOrder);
                setState(() {
                  final idx = _currentActivities
                      .indexWhere((a) => a.id == item.id);
                  if (idx != -1) {
                    final a = _currentActivities[idx];
                    _currentActivities[idx] = Activity(
                      id: a.id,
                      title: a.title,
                      description: a.description,
                      icon: a.icon,
                      date: a.date,
                      mediaUrl: a.mediaUrl,
                      mediaType: a.mediaType,
                      isVisible: a.isVisible,
                      orderIndex: newOrder,
                    );
                    // Optionally re-sort the local list
                    _currentActivities.sort((a, b) {
                      int cmp = a.orderIndex.compareTo(b.orderIndex);
                      if (cmp == 0) return b.date.compareTo(a.date);
                      return cmp;
                    });
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
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
