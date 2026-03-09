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
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        activity.icon,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(activity.title),
                    subtitle: Text(activity.description),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActivityDetailsPage(activity: activity),
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
