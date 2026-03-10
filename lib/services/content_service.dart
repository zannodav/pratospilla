import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb

class GalleryImage {
  final String id;
  final String url;
  final String category;
  final DateTime date;

  GalleryImage({
    required this.id,
    required this.url,
    required this.category,
    required this.date,
  });

  factory GalleryImage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryImage(
      id: doc.id,
      url: data['url'] as String? ?? '',
      category: data['category'] as String? ?? 'Interni',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Activity {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime date;
  final String? mediaUrl;
  final String? mediaType;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.date,
    this.mediaUrl,
    this.mediaType,
  });

  factory Activity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Activity(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      icon: data['icon'] as String? ?? 'hiking',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String?,
    );
  }
}

class ContentService {
  // Accedi alle istanze tramite getter per evitare errori se chiamate troppo presto
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  bool _firestoreAvailable = true;

  // Mock data as fallback
  final List<GalleryImage> _localGallery = [
    GalleryImage(
        id: '1',
        url:
            'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800',
        category: 'Interni',
        date: DateTime.now()),
    GalleryImage(
        id: '2',
        url: 'https://images.unsplash.com/photo-1542718610-a1d656d1884c?w=800',
        category: 'Interni',
        date: DateTime.now()),
    GalleryImage(
        id: '3',
        url:
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
        category: 'Territorio',
        date: DateTime.now()),
    GalleryImage(
        id: '4',
        url:
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800',
        category: 'Territorio',
        date: DateTime.now()),
  ];

  final List<Activity> _localActivities = [
    Activity(
        id: '1',
        title: 'Trekking',
        description: 'Sentieri boschivi',
        icon: 'hiking',
        date: DateTime.now()),
    Activity(
        id: '2',
        title: 'E-Bike',
        description: 'Percorsi ciclabili',
        icon: 'pedal_bike',
        date: DateTime.now()),
  ];

  /// --- GALLERY ---

  Future<List<GalleryImage>> fetchGallery() async {
    if (!_firestoreAvailable) return _localGallery;
    try {
      final snapshot = await _firestore
          .collection('gallery')
          .orderBy('date', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return _localGallery;
      return snapshot.docs
          .map((doc) => GalleryImage.fromFirestore(doc))
          .toList();
    } catch (e) {
      _firestoreAvailable = false;
      return _localGallery;
    }
  }

  Future<bool> addGalleryImage(XFile file, String category) async {
    try {
      String fileName =
          'gallery/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      Reference ref = _storage.ref().child(fileName);

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(file.path));
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await _firestore.collection('gallery').add({
        'url': url,
        'category': category,
        'date': Timestamp.now(),
      });
      return true;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return false;
    }
  }

  Future<bool> deleteGalleryImage(String id) async {
    try {
      await _firestore.collection('gallery').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting gallery image: $e');
      return false;
    }
  }

  /// --- ACTIVITIES ---

  Future<List<Activity>> fetchActivities() async {
    if (!_firestoreAvailable) return _localActivities;
    try {
      final snapshot = await _firestore
          .collection('activities')
          .orderBy('date', descending: true)
          .get();
      if (snapshot.docs.isEmpty) return _localActivities;
      return snapshot.docs.map((doc) => Activity.fromFirestore(doc)).toList();
    } catch (e) {
      _firestoreAvailable = false;
      return _localActivities;
    }
  }

  Future<bool> addActivity(String title, String description, String icon,
      {XFile? mediaFile}) async {
    try {
      String? mediaUrl;
      String? mediaType;

      if (mediaFile != null) {
        String fileName =
            'activities/${DateTime.now().millisecondsSinceEpoch}_${mediaFile.name}';
        Reference ref = _storage.ref().child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          uploadTask = ref.putData(await mediaFile.readAsBytes());
        } else {
          uploadTask = ref.putFile(File(mediaFile.path));
        }

        final snapshot = await uploadTask;
        mediaUrl = await snapshot.ref.getDownloadURL();

        // Basic check for PDF extension
        if (mediaFile.name.toLowerCase().endsWith('.pdf')) {
          mediaType = 'pdf';
        } else {
          mediaType = 'image';
        }
      }

      await _firestore.collection('activities').add({
        'title': title,
        'description': description,
        'icon': icon,
        'date': Timestamp.now(),
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (mediaType != null) 'mediaType': mediaType,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding activity: $e');
      return false;
    }
  }
  Future<bool> deleteActivity(String id) async {
    try {
      await _firestore.collection('activities').doc(id).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting activity: $e');
      return false;
    }
  }  
}
